"""
Script for PTQ using pytorch-quantization package
"""
import argparse
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torchvision.datasets as datasets
import torchvision.transforms as transforms
from _00_neural_nets import MLP, ConvNet
from pytorch_quantization import calib
from pytorch_quantization import nn as quant_nn
from pytorch_quantization import quant_modules
from pytorch_quantization.tensor_quant import QuantDescriptor
from torch.utils.data import DataLoader


def collect_stats(model, data_loader, num_bins):
    """Feed data to the network and collect statistic"""
    model.eval()
    # Enable calibrators
    for name, module in model.named_modules():
        if isinstance(module, quant_nn.TensorQuantizer):
            if module._calibrator is not None:
                module.disable_quant()
                module.enable_calib()
                if isinstance(module._calibrator, calib.HistogramCalibrator):
                    module._calibrator._num_bins = num_bins
            else:
                module.disable()

    for batch, _ in data_loader:
        x = batch.float()
        model(x)

        # Disable calibrators
        for _, module in model.named_modules():
            if isinstance(module, quant_nn.TensorQuantizer):
                if module._calibrator is not None:
                    module.enable_quant()
                    module.disable_calib()
                else:
                    module.enable()

def compute_amax(model, **kwargs):
    # Load calib result
    for name, module in model.named_modules():
        if isinstance(module, quant_nn.TensorQuantizer):
            if module._calibrator is not None:
                if isinstance(module._calibrator, calib.MaxCalibrator):
                    module.load_calib_amax()
                else:
                    module.load_calib_amax(**kwargs)
            print(F"{name:40}: {module}")


def quantize_model_params(model):
    """Quantize layer weights using calculated amax
       and process scale constant for C-code

    Args:
        state_dict (Dict): pytorch model state_dict
        amax (Dict): dictionary containing amax values
    """

    is_mlp = isinstance(model, MLP)

    indices = [0, 2, 4] if is_mlp else [0, 3, 7] 
    scale_factor = 127 # 127 for 8 bits

    
    state_dict = dict()

    for layer_idx, idx in enumerate(indices, start=1):
        # quantize all parameters
        # 모델 구조에 따라 키 이름이 다를 수 있으므로 확인
        if f'net.{idx}.weight' in model.state_dict():
            weight = model.state_dict()[f'net.{idx}.weight']
            s_w = model.state_dict()[f'net.{idx}._weight_quantizer._amax'].numpy()
            s_x = model.state_dict()[f'net.{idx}._input_quantizer._amax'].numpy()

            scale = weight * (scale_factor / s_w)
            state_dict[f'layer_{layer_idx}_weight'] = torch.clamp(scale.round(), min=-127, max=127).to(int)
            
            if is_mlp or layer_idx == 3:
                state_dict[f'layer_{layer_idx}_weight'] = state_dict[f'layer_{layer_idx}_weight'].T
            state_dict[f'layer_{layer_idx}_weight'] = state_dict[f'layer_{layer_idx}_weight'].numpy()
            
            # ==========================================
            # ★ [Bias 추출 및 양자화]
            # ==========================================
            if f'net.{idx}.bias' in model.state_dict():
                bias = model.state_dict()[f'net.{idx}.bias']
                
                # Bias 스케일 계산
                scale_bias = (scale_factor / s_x) * (scale_factor / s_w)
                
                # 차원 맞추기
                if len(scale_bias.shape) == 1:
                    scale_bias = torch.from_numpy(scale_bias).float()
                
                # 양자화 수행
                quantized_bias = (bias * scale_bias).round()
                
                state_dict[f'layer_{layer_idx}_bias'] = quantized_bias.int().numpy()
            # ==========================================

            state_dict[f'layer_{layer_idx}_s_x'] = scale_factor / s_x
            state_dict[f'layer_{layer_idx}_s_x_inv'] = s_x / scale_factor
            state_dict[f'layer_{layer_idx}_s_w_inv'] = (s_w / scale_factor).squeeze()        

    return state_dict
        

    
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Script for post-training quantization of a pre-trained model",
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    
    parser.add_argument('--filename', help='filename', type=str, default='convnet_mnist_new.th')
    parser.add_argument('--num_bins', help='number of bins', type=int, default=128)
    parser.add_argument('--data_dir', help='directory of folder containing the MNIST dataset', default='../data')
    parser.add_argument('--save_dir', help='save directory', default='../saved_models', type=Path)

    args = parser.parse_args()
    
    # load model
    file_path = args.save_dir / args.filename
    print(f"Loading model from: {file_path}")
    loaded_data = torch.load(file_path)    
    
    # ★ [수정 1] 저장 방식에 따라 유연하게 로드 (KeyError 방지)
    # 1. 만약 'state_dict' 키가 있는 딕셔너리 형태라면? (메타데이터 포함)
    if isinstance(loaded_data, dict) and 'state_dict' in loaded_data:
        state_dict = loaded_data['state_dict']
        channel_sizes = loaded_data.get('channel_sizes', [3, 3]) # 없으면 기본값 [3, 3]
        hidden_sizes = loaded_data.get('hidden_sizes', None)
    # 2. 만약 가중치만 바로 저장된 형태라면? (사용자님 케이스)
    else:
        state_dict = loaded_data
        # 학습 코드에서 channel_sizes=[3, 3]을 썼으므로 수동 설정
        channel_sizes = [3, 3] 
        hidden_sizes = None
        print(">>> Warning: No metadata found. Using default channel_sizes=[3, 3]")

    quant_nn.QuantLinear.set_default_quant_desc_input(QuantDescriptor(calib_method='histogram'))
    quant_nn.QuantConv2d.set_default_quant_desc_input(QuantDescriptor(calib_method='histogram'))
    quant_modules.initialize()

    # 모델 생성
    model = MLP(in_dim=28*28, hidden_sizes=hidden_sizes, out_dim=10) if 'mlp' in args.filename else ConvNet(channel_sizes=channel_sizes, out_dim=10)
    model.load_state_dict(state_dict)
    
    mnist_trainset = datasets.MNIST(root=args.data_dir, train=True, download=False, transform=transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize(
            (0.1307,), (0.3081,))]))

    train_loader = DataLoader(mnist_trainset, batch_size=len(mnist_trainset.data), num_workers=1, shuffle=False)

    print("Collecting stats for quantization...")
    with torch.no_grad():
        collect_stats(model, train_loader, args.num_bins)
        compute_amax(model, method="entropy")

    print("Quantizing parameters...")
    quantized_state_dict = quantize_model_params(model)
    
    # ★ [수정 2] 저장할 때는 다시 예쁘게 포장해서 저장
    output_data = {
        'state_dict': quantized_state_dict,
        'channel_sizes': channel_sizes,
        'hidden_sizes': hidden_sizes
    }

    if args.filename == 'convnet_mnist_new.th':
        name = 'convnet_mnist_quant_new.th'
    else:
        name = args.filename.replace('.th', '_quant.th')

    print(f"Saving quantized model to: {args.save_dir / name}")
    torch.save(output_data, args.save_dir / name)