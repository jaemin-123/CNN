"""
Script for training a simple MLP for classification on the MNIST dataset
"""
print("Starting script...")

import argparse
from pathlib import Path
import torch
import torch.nn as nn
import torchvision.datasets as datasets
import torchvision.transforms as transforms
from _00_neural_nets import ConvNet
from torch.optim import Adam
from torch.utils.data import DataLoader

def train_epoch(model, data_loader, optimizer, loss_fn):
    model.train()
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

# ★ [추가된 함수] 테스트용 (10,000장 평가)
def test_model(model, test_loader):
    model.eval()
    correct = 0
    total = 0
    print("\nStarting Test Evaluation...")
    with torch.no_grad():
        for x, y in test_loader:
            logits = model(x)
            preds = torch.argmax(logits, dim=1)
            correct += (preds == y).sum().item()
            total += y.size(0)
            
    acc = correct / total * 100
    print('='*50)
    print(f' [Final Test Result]')
    print(f' Total Images: {total}')
    print(f' Correct     : {correct}')
    print(f' Accuracy    : {acc:.2f}%')
    print('='*50 + '\n')
    return acc

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--save_dir', default='../saved_models', type=Path)
    parser.add_argument('--num_epochs', type=int, default=10) 
    args = parser.parse_args()
    
    # 1. 데이터셋 로드 (Train & Test)
    print("Loading MNIST dataset...")
    transform = transforms.Compose([
        transforms.ToTensor(), 
        transforms.Normalize((0.1307,), (0.3081,))
    ])
    
    mnist_trainset = datasets.MNIST(root='../data', train=True, download=True, transform=transform)
    # ★ [추가] 테스트 데이터셋 로드 (10,000장)
    mnist_testset = datasets.MNIST(root='../data', train=False, download=True, transform=transform)
    
    # 2. 모델 생성
    # ★ 중요: 하드웨어랑 맞추려면 bias=False가 필요하지만, 
    # _00_neural_nets.py를 안 고치셨으면 기본값(Bias=True)으로 학습됩니다.
    # 일단 기존 방식대로 학습 진행합니다.
    model = ConvNet(out_dim=10, channel_sizes=[3, 3])
    optimizer = Adam(model.parameters(), lr=0.001)
    loss_fn = nn.CrossEntropyLoss()
    
    train_loader = DataLoader(mnist_trainset, batch_size=128, shuffle=True)
    # ★ [추가] 테스트 로더
    test_loader = DataLoader(mnist_testset, batch_size=1000, shuffle=False)
    
    print(f"Start Training for {args.num_epochs} epochs...")
    
    # 3. 학습 루프
    for epoch in range(args.num_epochs): 
        loss, acc = train_epoch(model, train_loader, optimizer, loss_fn)
        print(f"Epoch: {epoch+1}/{args.num_epochs} | Loss: {loss:.4f} | Train Acc: {acc:.2f}%")
        
    # 4. 모델 저장
    args.save_dir.mkdir(exist_ok=True, parents=True)
    torch.save(model.state_dict(), args.save_dir / "convnet_mnist_new.th")
    print(f"Model saved to {args.save_dir / 'convnet_mnist_new.th'}")

    # ★ 5. [추가] 최종 10,000장 테스트 실행
    test_model(model, test_loader)