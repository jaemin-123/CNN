import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import datasets, transforms
import os

# ==========================================
# 1. 설정
# ==========================================
TEST_BATCH_SIZE = 1000
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
FILE_PATH = "../saved_models/convnet_mnist.th"  # 사용자님의 th 파일 이름

# ==========================================
# 2. 오리지널 모델 구조 정의 (Bias 포함)
# ==========================================
# 사용자 파일(th)의 내부 키가 'net.0.weight' 등으로 되어 있으므로
# self.net = nn.Sequential(...) 구조로 추정됩니다.
class OriginalCNN(nn.Module):
    def __init__(self):
        super(OriginalCNN, self).__init__()
        self.net = nn.Sequential(
            # Layer 0: Conv (Bias=True가 기본값)
            nn.Conv2d(1, 3, kernel_size=5, stride=1, padding=0, bias=True),
            # Layer 1: ReLU
            nn.ReLU(),
            # Layer 2: MaxPool
            nn.MaxPool2d(2),
            
            # Layer 3: Conv (Bias=True)
            nn.Conv2d(3, 3, kernel_size=5, stride=1, padding=0, bias=True),
            # Layer 4: ReLU
            nn.ReLU(),
            # Layer 5: MaxPool
            nn.MaxPool2d(2),
            
            # Layer 6: Flatten (구형 PyTorch에서는 없을 수도 있으나 일단 추가)
            nn.Flatten(),
            
            # Layer 7: FC (Bias=True)
            nn.Linear(3 * 4 * 4, 10, bias=True)
        )

    def forward(self, x):
        return self.net(x)

# ==========================================
# 3. 데이터 로드 (MNIST Test Set)
# ==========================================
def get_test_loader():
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    test_loader = torch.utils.data.DataLoader(
        datasets.MNIST('./data', train=False, download=True, transform=transform),
        batch_size=TEST_BATCH_SIZE, shuffle=False
    )
    return test_loader

# ==========================================
# 4. 테스트 함수
# ==========================================
def test(model, device, test_loader):
    model.eval()
    correct = 0
    with torch.no_grad():
        for data, target in test_loader:
            data, target = data.to(device), target.to(device)
            output = model(data)
            pred = output.argmax(dim=1, keepdim=True)
            correct += pred.eq(target.view_as(pred)).sum().item()

    accuracy = 100. * correct / len(test_loader.dataset)
    
    print('\n' + '='*50)
    print(f' [Original Model (.th) Evaluation]')
    print(f' File Loaded : {FILE_PATH}')
    print(f' Total Images: {len(test_loader.dataset)}')
    print(f' Correct     : {correct}')
    print(f' Accuracy    : {accuracy:.2f}%')
    print('='*50 + '\n')

# ==========================================
# 5. 메인 실행
# ==========================================
if __name__ == '__main__':
    # 1. 모델 생성
    model = OriginalCNN().to(DEVICE)
    
    # 2. 가중치 로드
    if os.path.exists(FILE_PATH):
        try:
            # .th 파일은 보통 dictionary 형태로 저장됨
            checkpoint = torch.load(FILE_PATH, map_location=DEVICE)
            
            # 만약 'state_dict' 키 안에 가중치가 있다면 꺼내옴
            if 'state_dict' in checkpoint:
                model.load_state_dict(checkpoint['state_dict'])
            else:
                model.load_state_dict(checkpoint)
                
            print(">>> Successfully loaded weights from .th file!")
            
        except Exception as e:
            print(f">>> Error loading file: {e}")
            print("    (키 이름이 안 맞거나 구조가 다를 수 있습니다.)")
            exit()
    else:
        print(f">>> File not found: {FILE_PATH}")
        exit()

    # 3. 테스트 실행
    test_loader = get_test_loader()
    test(model, DEVICE, test_loader)