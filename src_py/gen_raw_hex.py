import torch
import torchvision.datasets as datasets
import torchvision.transforms as transforms
from torch.utils.data import DataLoader
from pathlib import Path

# 설정
NUM_TEST = 1000
HEX_IMG_FILE = "raw_images_1000.hex" # 파일명 변경
HEX_LBL_FILE = "labels_1000.hex"

if __name__ == '__main__':
    print("Loading MNIST Dataset (RAW Mode)...")
    # ★ 중요: Normalize를 뺍니다! ToTensor만 하면 0.0~1.0이 되므로, 
    # 다시 255를 곱해서 0~255 정수로 만듭니다.
    test_dataset = datasets.MNIST(root='../data', train=False, download=True, 
                                transform=transforms.ToTensor())
    
    loader = DataLoader(test_dataset, batch_size=NUM_TEST, shuffle=False)
    images, labels = next(iter(loader))
    
    print(f"Generating RAW HEX files for {NUM_TEST} images...")
    
    with open(HEX_IMG_FILE, 'w') as f_img, open(HEX_LBL_FILE, 'w') as f_lbl:
        for i in range(NUM_TEST):
            # 0.0 ~ 1.0 범위의 텐서를 0 ~ 255 정수로 변환
            # (전처리/정규화 아무것도 안 한 상태)
            raw_img = (images[i] * 255.0).round().int().flatten().tolist()
            label = labels[i].item()
            
            # 파일 쓰기
            for pixel in raw_img:
                # 0~255 값을 2자리 hex로 (예: 255 -> ff, 0 -> 00)
                f_img.write(f"{pixel:02x}\n")
            
            f_lbl.write(f"{label:02x}\n")
            
            if (i+1) % 100 == 0: print(f"Processing {i+1}...")

    print("Done! Raw images generated.")