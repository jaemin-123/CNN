"""
Script for training a simple MLP for classification on the MNIST dataset
(Modified to include Testing/Validation)
"""
print("Starting script...")

import argparse
from pathlib import Path
import torch
import torch.nn as nn
import torchvision.datasets as datasets
import torchvision.transforms as transforms
# _00_neural_nets.py가 같은 폴더에 있어야 합니다.
from _00_neural_nets import ConvNet
from torch.optim import Adam
from torch.utils.data import DataLoader

def train_epoch(model, data_loader, optimizer, loss_fn):
    model.train() # 학습 모드 설정
    loss_sum = 0
    correct = 0
    total = 0
    for x, y in data_loader:
        optimizer.zero_grad()
        logits = model(x)
        loss = loss_fn(logits, y)
        loss.backward()
        optimizer.step()
        loss_sum += loss.item()
        
        # 정확도 계산
        preds = torch.argmax(logits, dim=1)
        correct += (preds == y).sum().item()
        total += y.size(0)
        
    acc = correct / total * 100
    return loss_sum / len(data_loader), acc

# [추가] 평가(테스트) 함수
def evaluate(model, data_loader, loss_fn):
    model.eval() # 평가 모드 설정 (Dropout, BatchNorm 등이 있다면 동작 변경됨)
    loss_sum = 0
    correct = 0
    total = 0
    
    with torch.no_grad(): # Gradient 계산 비활성화 (메모리 절약, 속도 향상)
        for x, y in data_loader:
            logits = model(x)
            loss = loss_fn(logits, y)
            loss_sum += loss.item()
            
            preds = torch.argmax(logits, dim=1)
            correct += (preds == y).sum().item()
            total += y.size(0)
            
    acc = correct / total * 100
    return loss_sum / len(data_loader), acc

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--save_dir', default='../saved_models', type=Path)
    parser.add_argument('--num_epochs', type=int, default=10) 
    args = parser.parse_args()
    
    # 데이터 전처리 설정
    transform = transforms.Compose([
        transforms.ToTensor(), 
        transforms.Normalize((0.1307,), (0.3081,))
    ])

    print("Loading MNIST dataset...")
    # 학습 데이터
    mnist_trainset = datasets.MNIST(root='../data', train=True, download=True, transform=transform)
    
    # [추가] 테스트 데이터
    mnist_testset = datasets.MNIST(root='../data', train=False, download=True, transform=transform)
    
    # 모델 생성 (Bias=False 버전)
    model = ConvNet(out_dim=10, channel_sizes=[3, 3])
    optimizer = Adam(model.parameters(), lr=0.001)
    loss_fn = nn.CrossEntropyLoss()
    
    # 데이터 로더 생성
    train_loader = DataLoader(mnist_trainset, batch_size=128, shuffle=True)
    # [추가] 테스트 로더 (Shuffle은 보통 False로 설정)
    test_loader = DataLoader(mnist_testset, batch_size=128, shuffle=False)
    
    print(f"Start Training for {args.num_epochs} epochs...")
    
    for epoch in range(args.num_epochs): 
        # 학습 수행
        train_loss, train_acc = train_epoch(model, train_loader, optimizer, loss_fn)
        
        # [추가] 테스트(검증) 수행
        test_loss, test_acc = evaluate(model, test_loader, loss_fn)
        
        # 결과 출력 (Train과 Test 결과를 같이 보여줌)
        print(f"Epoch: {epoch + 1}/{args.num_epochs} | "
              f"Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.2f}% | "
              f"Test Loss: {test_loss:.4f}, Test Acc: {test_acc:.2f}%")

    # 모델 저장
    if not args.save_dir.exists():
        args.save_dir.mkdir(parents=True)
        
    save_path = args.save_dir / 'convnet_mnist_quant.th'
    torch.save({
        'state_dict': model.state_dict(),
        'channel_sizes': [3, 3] 
    }, save_path)
    
    print(f"Model saved to {save_path}")