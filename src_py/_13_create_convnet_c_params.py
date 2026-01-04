"""
Script for Post-Training Quantization and C Parameter Export (All-in-One)
"""
import argparse
from pathlib import Path
import torch
import torch.nn as nn
import torchvision.datasets as datasets
import torchvision.transforms as transforms
from torch.utils.data import DataLoader
import numpy as np
import os

# _00_neural_nets.py에서 모델 구조 가져오기
from _00_neural_nets import ConvNet

def get_output_dim(input_dim, kernel_size, stride):
    output_dim = (input_dim -(kernel_size-1) - 1) / stride
    return int(output_dim + 1)

# 하드웨어 Multiplier 계산 함수 (S_in * S_w / S_out * 2^16)
def calculate_multiplier(scale_in, scale_w, scale_out):
    real_mult = (scale_in * scale_w) / scale_out
    int_mult = int(round(real_mult * (2**16)))
    return int_mult

# 텐서의 절대값 최대치를 이용해 스케일 계산 (S = Max / 127)
def get_scale(tensor):
    max_val = torch.max(torch.abs(tensor)).item()
    if max_val == 0: return 1.0
    return max_val / 127.0

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--filename', type=str, default='convnet_mnist_quant.th')
    parser.add_argument('--save_dir', default='../saved_models', type=Path)
    parser.add_argument('--data_dir', default='../data', type=str)
    args = parser.parse_args()

    # 1. 모델 및 가중치 로드
    print("1. Loading Model...")
    # Bias=False 설정으로 모델 생성
    model = ConvNet(out_dim=10, channel_sizes=[3, 3]) 
    
    model_path = args.save_dir / args.filename
    if not model_path.exists():
        print(f"Error: {model_path} not found. Run _11_train_convnet.py first!")
        exit(1)
        
    checkpoint = torch.load(model_path, map_location='cpu', weights_only=False)
    # state_dict 키 불일치 방지 (module. 접두어 제거 등)
    state_dict = checkpoint['state_dict']
    new_state_dict = {}
    for k, v in state_dict.items():
        name = k.replace("net.", "") # net.0.weight -> 0.weight
        new_state_dict[name] = v
    
    # 모델에 가중치 로드 (strict=False로 해서 일부 키 불일치 허용하되 확인)
    # 직접 state_dict를 꽂아넣기 위해 키 매핑을 수동으로 함
    # ConvNet 구조: 
    # 0: Conv1, 1: Pool, 2: ReLU, 3: Conv2, 4: Pool, 5: ReLU, 6: Flatten, 7: Linear
    
    weights = {}
    weights['layer_1'] = new_state_dict['0.weight']
    weights['layer_2'] = new_state_dict['3.weight']
    weights['layer_3'] = new_state_dict['7.weight']
    
    print("   Model weights loaded successfully.")

    # 2. Calibration (Activation Scale S_x 계산)
    print("2. Calibrating Activations (Calculating Scales)...")
    # MNIST 데이터 조금만 가져와서 흘려보냄
    test_dataset = datasets.MNIST(root=args.data_dir, train=False, download=True, 
                                transform=transforms.Compose([transforms.ToTensor(), transforms.Normalize((0.1307,), (0.3081,))]))
    loader = DataLoader(test_dataset, batch_size=100, shuffle=True)
    images, _ = next(iter(loader))
    
    # Hook을 걸어서 각 레이어의 출력값 범위를 캡처
    scales_x = {} # 입력 및 각 레이어 출력 스케일
    
    # Input Scale
    scales_x['input'] = get_scale(images)
    
    # Layer 1 Output Scale
    # Conv1 -> Pool1 -> ReLU (우리는 ReLU 이후 값을 캡처해야 함)
    # 파이썬 모델은 Conv->Pool->ReLU 순서지만 하드웨어는 Conv->ReLU->Pool일수도 있음. 
    # 하지만 MaxPool은 스케일을 바꾸지 않으므로 Conv 출력만 봐도 됨.
    # 여기서는 간단히 순전파 직접 실행
    
    x = images
    # L1: Conv
    l1_out = torch.nn.functional.conv2d(x, weights['layer_1'], stride=1)
    scales_x['layer_1'] = get_scale(torch.nn.functional.relu(l1_out)) # ReLU 통과 후 스케일
    
    # L1 Pool
    l1_pool = torch.nn.functional.max_pool2d(l1_out, 2, 2)
    l1_relu = torch.nn.functional.relu(l1_pool)
    
    # L2: Conv
    l2_out = torch.nn.functional.conv2d(l1_relu, weights['layer_2'], stride=1)
    scales_x['layer_2'] = get_scale(torch.nn.functional.relu(l2_out))
    
    # L2 Pool
    l2_pool = torch.nn.functional.max_pool2d(l2_out, 2, 2)
    l2_relu = torch.nn.functional.relu(l2_pool)
    l2_flat = l2_relu.flatten(1)
    
    # L3: Linear (FC)
    l3_out = torch.nn.functional.linear(l2_flat, weights['layer_3'])
    scales_x['layer_3'] = get_scale(l3_out) # FC 출력 스케일

    # Weight Scales
    scales_w = {}
    scales_w['layer_1'] = get_scale(weights['layer_1'])
    scales_w['layer_2'] = get_scale(weights['layer_2'])
    scales_w['layer_3'] = get_scale(weights['layer_3'])
    
    print(f"   S_x (Input): {scales_x['input']:.4f}")
    print(f"   S_x (L1): {scales_x['layer_1']:.4f}, S_w (L1): {scales_w['layer_1']:.4f}")
    print(f"   S_x (L2): {scales_x['layer_2']:.4f}, S_w (L2): {scales_w['layer_2']:.4f}")
    print(f"   S_x (L3): {scales_x['layer_3']:.4f}, S_w (L3): {scales_w['layer_3']:.4f}")

    # 3. Multiplier 계산 (중요!)
    mults = []
    # L1 Multiplier = S_in * S_w1 / S_out1
    mult_l1 = calculate_multiplier(scales_x['input'], scales_w['layer_1'], scales_x['layer_1'])
    # L2 Multiplier = S_out1 * S_w2 / S_out2
    mult_l2 = calculate_multiplier(scales_x['layer_1'], scales_w['layer_2'], scales_x['layer_2'])
    # FC Multiplier = S_out2 * S_w3 / S_out3
    mult_fc = calculate_multiplier(scales_x['layer_2'], scales_w['layer_3'], scales_x['layer_3'])

    print("\n" + "="*50)
    print("   [IMPORTANT] NEW MULTIPLIERS FOR C CODE")
    print("   Copy these values into 'convnet.c' or 'main_8.c'")
    print(f"   Layer 1 Multiplier: {mult_l1}")
    print(f"   Layer 2 Multiplier: {mult_l2}")
    print(f"   FC Layer Multiplier: {mult_fc}")
    print("="*50 + "\n")

    # 4. C 헤더 및 소스 파일 작성
    print("3. Writing C Files...")
    
    # 헤더 파일
    with open('../src/convnet_params.h', 'w') as f:
        f.write('#ifndef CONVNET_PARAMS\n#define CONVNET_PARAMS\n#include <stdint.h>\n\n')
        # 상수 정의
        f.write(f'#define INPUT_DIM {28*28}\n')
        f.write(f'#define OUTPUT_DIM {10}\n\n')
        
        # 더미 변수 선언 (기존 코드 호환용, 실제론 안씀)
        for i in range(1, 4):
            f.write(f"extern const int layer_{i}_s_x;\n")
            f.write(f"extern const int layer_{i}_s_x_inv;\n")
            f.write(f"extern const int layer_{i}_s_w_inv[1];\n") # 배열로 선언

        # 가중치 선언
        for i in range(1, 4):
            val_len = len(weights[f'layer_{i}'].flatten())
            f.write(f"extern const int8_t layer_{i}_weight[{val_len}];\n")
            
        f.write('\n#endif\n')

    # 소스 파일
    with open('../src/convnet_params.c', 'w') as f:
        f.write('#include "convnet_params.h"\n\n')
        
        # 더미 변수 정의 (0으로 채움, 컴파일 에러 방지)
        for i in range(1, 4):
            f.write(f"const int layer_{i}_s_x = 0;\n")
            f.write(f"const int layer_{i}_s_x_inv = 0;\n")
            f.write(f"const int layer_{i}_s_w_inv[1] = {{0}};\n")

        # 가중치 데이터 작성 (Quantized int8)
        for i in range(1, 4):
            w_float = weights[f'layer_{i}']
            s_w = scales_w[f'layer_{i}']
            # Quantize: Float / Scale -> Round -> Clip
            w_quant = torch.round(w_float / s_w).int()
            w_quant = torch.clamp(w_quant, -128, 127).flatten().tolist()
            
            f.write(f"const int8_t layer_{i}_weight[{len(w_quant)}] = {{")
            for idx, val in enumerate(w_quant):
                f.write(str(val))
                if idx < len(w_quant) - 1: f.write(", ")
            f.write("};\n\n")

    print("Done! 'convnet_params.c' has been created.")