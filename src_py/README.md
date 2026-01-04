
# Project: MNIST CNN Implementation on FPGA (SW-HW Co-design)

## 1. Project Overview
이 프로젝트는 PyTorch로 학습된 CNN 모델을 FPGA 하드웨어(Verilog)에 탑재하기 위해, **Float32 모델 학습**부터 **Int8 양자화(Quantization)**까지의 전체 SW 파이프라인을 구축하고 하드웨어 동작을 검증한 결과물입니다.

* **Target:** MNIST Digit Classification
* **Input:** 28x28 Grayscale Image
* **Precision:** INT8 (8-bit Integer) Post-Training Quantization
* **Performance:**
    * Python Golden Model: **96.10%**
    * Verilog Simulation: **96.10%** (Bit-exact match verified)

---

## 2. Model Training & Preprocessing (학습 및 전처리)
**File:** `scripts/_11_train_convnet.py`

하드웨어 구현을 최적화하기 위해 학습 단계에서부터 하드웨어의 제약 사항을 고려하여 모델을 설계했습니다.

### 2.1 Why Normalization? (왜 정규화를 했는가?)
학습 시 입력 데이터(0~255)를 그대로 사용하지 않고, 평균 0.1307, 표준편차 0.3081로 **정규화(Normalization)**하여 학습했습니다.

## CODE_INSERT_1

이 전처리 과정은 단순한 학습 성능 향상뿐만 아니라 **하드웨어 구현**을 위해 필수적입니다.

1.  **SW 관점 (학습 성능):**
    * 입력 데이터 분포를 0을 중심으로 재배치(Zero-centering)하여, Gradient Descent 과정에서 가중치 업데이트가 안정적이고 빠르게 수렴하도록 돕습니다.
2.  **HW 관점 (양자화 및 리소스):**
    * 데이터 분포를 종 모양(Gaussian-like)으로 모아주어 **8-bit Quantization 시 정보 손실을 최소화**합니다.
    * 0~255의 큰 값을 그대로 연산하면 Accumulator의 비트 수가 커져야 하지만, 정규화된 작은 값을 사용하면 **하드웨어 리소스(Flip-flops, Logic elements)를 절약**할 수 있습니다.

### 2.2 Model Architecture
* **Bias-Free Design:** FPGA 내의 Adder 리소스를 절약하기 위해 모든 레이어에서 Bias를 제거하거나 최소화하였습니다.
* **Structure:** Conv(5x5) -> ReLU -> MaxPool -> Conv(5x5) -> ReLU -> MaxPool -> FC

---

## 3. Hardware Implementation: Preprocessing Unit

학습된 모델은 정규화된 입력을 기대하므로, FPGA 입력단에 이를 처리할 **전처리 모듈(Preprocessing Unit)**을 직접 설계하여 구현했습니다.

### 3.1 Implementation Strategy (구현 전략)
FPGA 내부에서 부동소수점(Float) 나눗셈을 수행하는 것은 면적과 성능 면에서 매우 비효율적입니다. 따라서 학습 때 사용한 정규화 수식을 **정수 곱셈과 비트 시프트(Integer Arithmetic)**로 변환하여 구현했습니다.

* **Software Formula:**
    $Input_{norm} = (Pixel - Mean) / Std$
* **Hardware Formula:**
    $Input_{int8} = (Pixel \times Multiplier) \gg Shift - Offset$

이 방식을 통해 0~255의 Raw Pixel 데이터를 모델이 학습한 분포인 **-19 ~ 127 범위의 Signed Integer**로 단 1클럭 만에 변환하여 CNN 코어에 전달합니다.

---

## 4. Post-Training Quantization (사후 양자화)
**File:** `scripts/_02_quantize_package_new.py`

학습된 Float32 가중치를 FPGA 연산에 맞게 Int8로 변환하기 위해 NVIDIA의 `pytorch-quantization` 툴킷을 사용했습니다.

## CODE_INSERT_2

* **Calibration:** 입력 데이터의 분포(Histogram)를 수집하고, 정보 손실(Entropy)이 가장 적은 최적의 범위(`amax`)를 찾아 스케일링 팩터를 결정했습니다.
* **Scale Factor Extraction:** 하드웨어의 `Requantizer` 모듈에서 나눗셈 없이 비트 시프트만으로 연산하기 위해, 스케일의 역수(Inverse Scale)를 미리 계산하여 `.th` 파일에 저장했습니다.

---

## 5. Verification (검증)
Python으로 작성된 하드웨어 동작 시뮬레이터와 실제 Verilog RTL 시뮬레이션 결과를 비교 검증했습니다.

* **Python Simulator:** 양자화된 파라미터와 정수 연산 로직을 파이썬으로 모사하여 Golden Reference를 생성했습니다.
* **Result:** 초기 가중치 순서 불일치 문제를 해결하고, 전처리 상수를 업데이트한 결과 **96% 이상의 정확도**를 달성하며 SW와 HW 결과가 일치함을 확인했습니다.

---
---

## Appendix: Key Code Snippets

### CODE_INSERT_1: Data Normalization (in `_11_train_convnet.py`)
```python
# 하드웨어 입력 조건과 동일한 분포를 만들기 위한 전처리
transform = transforms.Compose([
    transforms.ToTensor(), 
    # Mean: 0.1307, Std: 0.3081 (MNIST Dataset Statistics)
    transforms.Normalize((0.1307,), (0.3081,)) 
])
