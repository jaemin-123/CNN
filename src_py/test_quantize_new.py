import torch
import torch.nn as nn
from torchvision import datasets, transforms
from _00_neural_nets import ConvNet
from torch.utils.data import DataLoader
import numpy as np
import os

# ==========================================
# 1. 설정
# ==========================================
FILE_PATH = "../saved_models/convnet_mnist_quant_new.th"
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

def load_quantized_weights_to_model(model, quant_path):
    print(f"Loading Quantized Dict: {quant_path}")
    # weights_only=False는 PyTorch 보안 경고 우회용
    saved_data = torch.load(quant_path, map_location='cpu', weights_only=False)
    
    # 만약 state_dict 키 안에 들어있다면 꺼내기
    if 'state_dict' in saved_data:
        q_dict = saved_data['state_dict']
    else:
        q_dict = saved_data

    # =========================================================
    # ★ 핵심: 하드웨어용 이름(layer_1) -> 파이토치용 이름(net.0) 매핑 및 복원
    # =========================================================
    # Layer 1 (Conv)
    # Weight 복원: Int값 * Scale_Factor
    w1_int = q_dict['layer_1_weight'] # numpy array
    s_w1_inv = q_dict['layer_1_s_w_inv'] 
    w1_float = w1_int * s_w1_inv.reshape(-1, 1, 1, 1) # 차원 맞추기
    model.net[0].weight.data = torch.from_numpy(w1_float).float()
    
    # Bias 복원 (저장된 경우)
    if 'layer_1_bias' in q_dict:
        b1_int = q_dict['layer_1_bias']
        s_x1_inv = q_dict['layer_1_s_x_inv'] # Input Scale Inv
        # Bias Scale = Scale_Input * Scale_Weight
        # 복원하려면: Bias_Int * (Scale_Input_Inv * Scale_Weight_Inv)
        b1_float = b1_int * (s_x1_inv * s_w1_inv)
        model.net[0].bias.data = torch.from_numpy(b1_float).float()

    # Layer 2 (Conv) - net[3]
    w2_int = q_dict['layer_2_weight']
    s_w2_inv = q_dict['layer_2_s_w_inv']
    w2_float = w2_int * s_w2_inv.reshape(-1, 1, 1, 1)
    model.net[3].weight.data = torch.from_numpy(w2_float).float()
    
    if 'layer_2_bias' in q_dict:
        b2_int = q_dict['layer_2_bias']
        s_x2_inv = q_dict['layer_2_s_x_inv']
        b2_float = b2_int * (s_x2_inv * s_w2_inv)
        model.net[3].bias.data = torch.from_numpy(b2_float).float()

    # Layer 3 (FC) - net[7] (Flatten이 있어서 인덱스 확인 필요, 보통 끝부분)
    # ConvNet 구조상 net[7]이 Linear라고 가정
    w3_int = q_dict['layer_3_weight'] # (Out, In) or (In, Out)
    s_w3_inv = q_dict['layer_3_s_w_inv']
    
    # 저장할 때 Transpose(.T)를 했었는지 확인해서 형상 맞춤
    target_shape = model.net[7].weight.data.shape
    if w3_int.shape != target_shape:
        w3_int = w3_int.T
        
    w3_float = w3_int * s_w3_inv.reshape(-1, 1)
    model.net[7].weight.data = torch.from_numpy(w3_float).float()
    
    if 'layer_3_bias' in q_dict:
        b3_int = q_dict['layer_3_bias']
        s_x3_inv = q_dict['layer_3_s_x_inv']
        b3_float = b3_int * (s_x3_inv * s_w3_inv)
        model.net[7].bias.data = torch.from_numpy(b3_float).float()

    return model

def test_final():
    # 1. 모델 껍데기 생성 (채널 사이즈 [3,3] 고정)
    model = ConvNet(out_dim=10, channel_sizes=[3, 3]).to(DEVICE)
    
    # 2. 하드웨어용 파라미터를 복원해서 주입
    try:
        model = load_quantized_weights_to_model(model, FILE_PATH)
        model.to(DEVICE)
        print(">>> Successfully reconstructed model from quantized parameters!")
    except Exception as e:
        print(f"\n[Error] 복원 중 오류 발생: {e}")
        print("키 이름이 안 맞을 수 있습니다. _12_quantize.py에서 저장한 키 이름을 확인하세요.")
        return

    # 3. 데이터 로드
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    test_loader = DataLoader(
        datasets.MNIST('../data', train=False, download=True, transform=transform),
        batch_size=1000, shuffle=False
    )

    # 4. 테스트
    model.eval()
    correct = 0
    total = 0
    print("\nRunning Inference on 10,000 images...")
    
    with torch.no_grad():
        for data, target in test_loader:
            data, target = data.to(DEVICE), target.to(DEVICE)
            output = model(data)
            pred = output.argmax(dim=1, keepdim=True)
            correct += pred.eq(target.view_as(pred)).sum().item()
            total += target.size(0)

    acc = 100. * correct / total
    
    print('\n' + '='*50)
    print(f' [Quantized Hardware Simulation Result]')
    print(f' File        : {FILE_PATH}')
    print(f' Accuracy    : {acc:.2f}%')
    print('='*50 + '\n')

if __name__ == '__main__':
    if os.path.exists(FILE_PATH):
        test_final()
    else:
        print(f"Error: File not found ({FILE_PATH})")