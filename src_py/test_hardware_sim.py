import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
import numpy as np
import os

# ==========================================
# 1. 설정
# ==========================================
FILE_PATH = "../saved_models/convnet_mnist_quant_new.th"
DEVICE = torch.device("cpu")
NUM_TEST_IMAGES = 1000

def hardware_simulate(file_path):
    print(f"Loading Quantized Parameters from: {file_path}")
    saved_data = torch.load(file_path, map_location='cpu', weights_only=False)
    
    if isinstance(saved_data, dict) and 'state_dict' in saved_data:
        q_dict = saved_data['state_dict']
    else:
        q_dict = saved_data

    # -------------------------------------------------------
    # 2. 파라미터 로딩
    # -------------------------------------------------------
    def get_param(key):
        return torch.from_numpy(q_dict[key]).float() 

    def get_bias(key, out_channels):
        if key in q_dict:
            return torch.from_numpy(q_dict[key]).float()
        else:
            return torch.zeros(out_channels).float()
            
    def get_scale(key):
        val = q_dict[key]
        return torch.as_tensor(val).float()

    # ★ 중요 수정: * 127.0 제거! (저장된 값이 이미 Step Size임)
    
    # [Layer 1]
    w1 = get_param('layer_1_weight')
    b1 = get_bias('layer_1_bias', w1.shape[0]) 
    s_x1 = get_scale('layer_1_s_x_inv') # Input Step Size
    s_w1 = get_scale('layer_1_s_w_inv') # Weight Step Size
    
    # [Layer 2]
    w2 = get_param('layer_2_weight')
    b2 = get_bias('layer_2_bias', w2.shape[0])
    s_x2 = get_scale('layer_2_s_x_inv')
    s_w2 = get_scale('layer_2_s_w_inv')

    # [Layer 3 (FC)]
    w3 = get_param('layer_3_weight')
    if w3.shape[0] == 10 and w3.shape[1] == 48:
        w3 = w3.T 
    b3 = get_bias('layer_3_bias', 10)
    s_x3 = get_scale('layer_3_s_x_inv')
    s_w3 = get_scale('layer_3_s_w_inv')

    # -------------------------------------------------------
    # 3. Re-scale Factor 계산
    # -------------------------------------------------------
    def safe_reshape(tensor):
        if tensor.numel() > 1:
            return tensor.reshape(-1, 1, 1)
        else:
            return tensor

    # 공식: M = (S_in * S_w) / S_out
    rescale_1 = (s_x1 * safe_reshape(s_w1)) / s_x2
    rescale_2 = (s_x2 * safe_reshape(s_w2)) / s_x3
    
    print(">>> Parameters loaded and Scale Factors calculated (Corrected).")

    # -------------------------------------------------------
    # 4. 데이터 로드
    # -------------------------------------------------------
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    test_dataset = datasets.MNIST('../data', train=False, download=True, transform=transform)
    test_loader = DataLoader(test_dataset, batch_size=1, shuffle=False) 

    # -------------------------------------------------------
    # 5. 하드웨어 동작 시뮬레이션
    # -------------------------------------------------------
    correct = 0
    total = 0
    
    print(f"\nRunning Integer-based Simulation on {NUM_TEST_IMAGES} images...")
    
    for i, (image, label) in enumerate(test_loader):
        if i >= NUM_TEST_IMAGES: break 
        
        # [Step 0] Input Quantization
        # Float Input을 Int8로 변환: Input / Step_Size
        scale_in = s_x1 if s_x1.numel() == 1 else s_x1[0]
        
        # ★ 수정: image / (scale / 127) 이 아니라 image / scale 입니다.
        input_int = torch.round(image / scale_in)
        input_int = torch.clamp(input_int, -128, 127)

        # [Step 1] Layer 1
        out1_acc = F.conv2d(input_int, w1, stride=1, padding=0)
        out1_acc = out1_acc + b1.reshape(1, -1, 1, 1)
        
        # Re-scale
        out1_scaled = out1_acc * rescale_1
        out1_int = torch.round(out1_scaled)
        out1_int = torch.clamp(out1_int, -128, 127)
        out1_int = F.relu(out1_int)
        out1_pool = F.max_pool2d(out1_int, 2)
        
        # [Step 2] Layer 2
        out2_acc = F.conv2d(out1_pool, w2, stride=1, padding=0)
        out2_acc = out2_acc + b2.reshape(1, -1, 1, 1)
        
        out2_scaled = out2_acc * rescale_2
        out2_int = torch.round(out2_scaled)
        out2_int = torch.clamp(out2_int, -128, 127)
        out2_int = F.relu(out2_int)
        out2_pool = F.max_pool2d(out2_int, 2)
        
        # [Step 3] FC Layer
        out_flat = out2_pool.view(1, -1)
        out3_acc = torch.matmul(out_flat, w3)
        out3_acc = out3_acc + b3
        
        # Result
        final_out = out3_acc
        pred = final_out.argmax(dim=1, keepdim=True)
        if pred.item() == label.item():
            correct += 1
        total += 1

    acc = 100. * correct / total
    print('='*50)
    print(f' [Hardware Simulation Result (Integer Logic)]')
    print(f' Total Images: {total}')
    print(f' Correct     : {correct}')
    print(f' Accuracy    : {acc:.2f}%')
    print('='*50 + '\n')

if __name__ == '__main__':
    if os.path.exists(FILE_PATH):
        hardware_simulate(FILE_PATH)
    else:
        print(f"Error: File not found ({FILE_PATH})")