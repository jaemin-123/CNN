import torch
import torchvision.datasets as datasets
import torchvision.transforms as transforms
from torch.utils.data import DataLoader
from pathlib import Path
import argparse

# ==========================================
# 설정
# ==========================================
NUM_TEST = 1000  # 1000개 테스트
HEX_IMG_FILE = "images_1000.hex"
HEX_LBL_FILE = "labels_1000.hex"

def get_scale(tensor):
    max_val = torch.max(torch.abs(tensor)).item()
    return max_val / 127.0 if max_val != 0 else 1.0

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    # 모델 파일 경로가 맞는지 꼭 확인하세요!
    parser.add_argument('--filename', type=str, default='convnet_mnist_quant.th') 
    parser.add_argument('--save_dir', default='../saved_models', type=Path)
    parser.add_argument('--data_dir', default='../data', type=str)
    args = parser.parse_args()

    # 1. 데이터셋 로드
    print("Loading MNIST Dataset...")
    test_dataset = datasets.MNIST(root=args.data_dir, train=False, download=True, 
                                transform=transforms.Compose([transforms.ToTensor(), transforms.Normalize((0.1307,), (0.3081,))]))
    
    # 2. Calibration (Scale 값 계산 - 기존과 동일하게 유지)
    print("Calibrating Scale...")
    calib_img, _ = test_dataset[0]
    s_in = get_scale(calib_img)
    print(f"Input Scale (s_in): {s_in}")

    # 3. 데이터 생성 및 파일 저장
    print(f"Generating HEX files for {NUM_TEST} images...")
    
    loader = DataLoader(test_dataset, batch_size=NUM_TEST, shuffle=False)
    images, labels = next(iter(loader))
    
    with open(HEX_IMG_FILE, 'w') as f_img, open(HEX_LBL_FILE, 'w') as f_lbl:
        for i in range(NUM_TEST):
            # 이미지 Quantization (Float -> Int8)
            img_tensor = images[i]
            q_img = torch.clamp(torch.round(img_tensor / s_in), -128, 127).int().flatten().tolist()
            
            # 라벨 저장
            label = labels[i].item()
            
            # 파일 쓰기
            # Verilog $readmemh는 띄어쓰기나 줄바꿈으로 구분된 16진수 값을 읽습니다.
            # 이미지: 픽셀 데이터를 줄바꿈으로 기록
            for pixel in q_img:
                # 음수 처리: 8비트 hex로 변환 (예: -1 -> ff)
                hex_val = pixel & 0xFF 
                f_img.write(f"{hex_val:02x}\n")
            
            # 라벨: 한 줄에 하나씩
            f_lbl.write(f"{label:02x}\n")
            
            if (i+1) % 100 == 0:
                print(f"  Processed {i+1}/{NUM_TEST} images...")

    print("\nDone!")
    print(f"Created '{HEX_IMG_FILE}' (Size: {NUM_TEST*784} lines)")
    print(f"Created '{HEX_LBL_FILE}' (Size: {NUM_TEST} lines)")