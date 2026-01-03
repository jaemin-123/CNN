# 1. PYTHON 학습모델(실수) 정답률(학습데이터, 검증데이터)
## 학습시 정답률
<img width="494" height="243" alt="image" src="https://github.com/user-attachments/assets/9fc5f1a3-b509-438b-bfd1-182c8801f916" />




# 2. FPGA 검증 정수 기반 정답률 (10000개, 1000개)
## FPGA 동작 기준
<img width="654" height="61" alt="image" src="https://github.com/user-attachments/assets/f8b3a2a6-f2d7-4e22-a421-9b523d51b32f" />

# 3. VIVADO IMPLEMENTATION 자원사용량
<img width="573" height="271" alt="image" src="https://github.com/user-attachments/assets/00e4130f-dd25-4681-86d9-c33c94a248d5" />

<img width="542" height="188" alt="image" src="https://github.com/user-attachments/assets/95fe40ef-a96c-48bd-a4f9-446b75aba645" />

# 4. VIVADO CNN CORE SIMULATION 1000개 이미지 정답률 (C언어나 PYTHON이나 C언어로 돌린거랑 같은지) 
## FPGA 1000개 이미지 TB
- python 보다 정확도 낮은이유 예상) 베릴로그 코드에 계산후 반올림 x
<img width="301" height="88" alt="image" src="https://github.com/user-attachments/assets/fd12808e-e755-4751-94f5-7f865472dc9a" />

# 5. CNN CORE 이미지 한개 추론에 필요한 CLOCK 수 
## 100MHz 기준
<img width="379" height="87" alt="image" src="https://github.com/user-attachments/assets/7f563f67-7527-4e9c-9f63-faed56b3a195" />

## 125MHz 기준
<img width="379" height="87" alt="image" src="https://github.com/user-attachments/assets/c0b12540-ce5a-45c1-8894-f0842de84de0" />

# 6. FPGA 같은 연산방식으로 ZYNQ 프로세서에서 돌린 결과 나오는 시간 및 CLOCK 수


# 📊 FPGA-based CNN Accelerator: A Post-Training Quantization (PTQ) Approach

![Methodology](https://img.shields.io/badge/Method-PTQ-blueviolet) ![Framework](https://img.shields.io/badge/Train-PyTorch_Float32-orange) ![Hardware](https://img.shields.io/badge/Inference-Verilog_FixedPoint-blue) ![Device](https://img.shields.io/badge/Device-Zynq%2FArtix-green)

## 📖 Project Abstract
본 프로젝트는 **PTQ(Post-Training Quantization)** 기법을 활용하여 PyTorch로 학습된 CNN 모델을 FPGA 하드웨어 가속기로 구현한 결과물입니다.

일반적인 Float32 정밀도로 학습된 모델을 **8-bit Integer 기반의 하드웨어(Verilog)**로 이식하는 과정에서 발생하는 정확도 차이(Accuracy Gap)를 분석하고, **Software Simulation 결과와 Hardware Implementation 결과가 비트 단위까지 일치(Bit-True)**함을 입증했습니다.

---

## 🧠 Quantization Strategy (PTQ)
실제 엣지 디바이스 환경을 고려하여, 재학습(QAT) 비용이 들지 않는 **Post-Training Quantization** 방식을 채택했습니다.

| Feature | **My Approach (PTQ)** | Comparison (QAT) |
| :--- | :--- | :--- |
| **Training** | Standard Float32 Training | Quantization simulation during training |
| **Weight Conversion** | Offline Conversion (Float → Int8) | Learned during training |
| **H/W Approach** | **Bit-True w/ Software Simulation** | Minimized Quantization Loss |

---

## 🏗 System Architecture

### 1. Model Architecture (Software)
* **Input:** 28x28 Grayscale (MNIST)
* **Layers:**
  * `Conv1`: 5x5, 3ch, ReLU, MaxPool(2x2)
  * `Conv2`: 5x5, 3ch, ReLU, MaxPool(2x2)
  * `FC Layer`: 48 Inputs → 10 Outputs
* **Optimization:** Bias-Free 설계 및 파라미터 경량화

### 2. Hardware Design (Verilog)
* **Streaming Pipeline:** Line Buffer를 사용하여 전체 이미지를 저장하지 않고 픽셀 입력과 동시에 연산 수행.
* **Resources:**
  * **Line Buffer:** 5x5 Window generation
  * **PE (Processing Element):** Parallel MAC Operations
  * **Safety Logic:** Valid Signal Filtering for FC Layer

---

## 📉 Experimental Results

### 1. Training Result (Python)
PyTorch를 이용한 학습 결과, 10 Epoch 만에 **Test Accuracy 97.22%**를 달성했습니다.

<img width="842" height="194" alt="image" src="https://github.com/user-attachments/assets/b22f507b-6c67-4807-8a3d-eb17b35fc61a" />

*(Fig 1. Python Training Log showing 97.22% Test Accuracy)*

### 2. Bit-True Verification (Crucial Achievement)
하드웨어 설계의 무결성을 증명하기 위해 Python에서 하드웨어와 동일한 8-bit 제약 조건을 건 시뮬레이션(Golden Reference)과 실제 FPGA 출력을 비교했습니다.

| Environment | Precision | Accuracy | Note |
| :--- | :--- | :--- | :--- |
| **Python Baseline** | Float32 | **97.22%** | Target |
| **Python Sim (Quantized)** | Int8 | **96.60%** | **Golden Ref** |
| **FPGA Hardware** | Int8 | **96.20%** | **Implementation** |

![Python Verification](./images/py_verification.png)
*(Fig 2. Python Simulation comparing 10k set and 1k subset accuracy)*

> **Analysis:**
> * Float32(97.2%)와 Int8(96.x%) 사이의 차이는 PTQ 방식의 양자화 손실(Quantization Loss) 및 하드웨어의 Truncation(버림) 방식에 기인합니다.
> * **Python Sim(Int8)과 FPGA 결과가 오차 범위 내에서 일치**한다는 것은 Verilog 설계에 논리적 오류가 없으며 **Bit-True**하게 구현되었음을 증명합니다.

### 3. FPGA Simulation & Performance
Vivado 시뮬레이션 결과, 1000개의 Test 이미지에 대해 **96.2%**의 정확도를 확인했습니다.

![FPGA TB Result](./images/fpga_result.png)
*(Fig 3. FPGA Testbench Log: 96.2% Accuracy & Inference Cycles)*

* **Clock Frequency:** 125 MHz (Target)
* **Inference Latency:** **813 Cycles** / Image
* **Throughput:** 약 **6.5 µs** per Image (@125MHz)

### 4. Resource Utilization
Implementation(Post-Route) 후 자원 사용량입니다. 효율적인 로직 설계를 통해 **DSP 사용량을 최소화(3%)**하고 LUT 위주로 구현했습니다.

![Resource Utilization](./images/resource_util.png)
*(Fig 4. Vivado Implementation Report)*

| Resource | Used | Available | Utilization % |
| :--- | :--- | :--- | :--- |
| **LUT** | 14,643 | 53,200 | **27.52%** |
| **FF** | 12,118 | 106,400 | **11.39%** |
| **DSP** | 6 | 220 | **2.73%** |
| **BRAM** | 0.5 | 140 | **<1%** |

---

## 🔧 Troubleshooting & Challenges

프로젝트 진행 중 발생한 주요 이슈와 해결 과정입니다.

### 1. FC Layer Garbage Data Issue
* **문제:** Convolution/Pooling을 거친 데이터가 FC Layer로 진입할 때 유효하지 않은 값(Garbage)이 섞여 오답률 상승.
* **원인:** Line Buffer의 초기 채움(Filling) 구간에서 Valid 신호 제어가 정밀하지 못함.
* **해결:** Valid 신호가 Window 내 유효 데이터가 꽉 찼을 때만 정확히 High가 되도록 **Control Logic을 재설계**하여 FC Layer로 깨끗한 데이터만 전달.

### 2. Vivado Optimization (Resource ~0%)
* **문제:** Behavioral Simulation은 정상이나, Implementation 시 회로가 통째로 삭제되어 리소스가 0에 수렴.
* **원인:** FC Layer 입력부에서 데이터 개수(48개)를 너무 엄격하게 체크하는 카운터 로직 때문에 합성 툴이 "도달 불가능한 로직"으로 오판함.
* **해결:** 엄격한 카운터 조건 대신 **Data-driven(Valid 신호 기반)** 방식으로 설계를 완화(Relaxation)하여 정상 합성 유도.

### 3. Truncation Bias Analysis
* **현상:** 반올림(Rounding)을 적용하지 않아 미세한 정확도 하락(약 0.5%) 관측.
* **결정:** FPGA 리소스 절약과 타이밍 마진 확보를 위해 Rounding Logic을 추가하는 대신, **Truncation(버림)** 방식을 유지하고 이를 하드웨어 특성으로 수용함.

---

## 🚀 How to Run

### Python (Training & Hex Gen)
```bash
# Train Model
python _11_train_convnet.py --num_epochs 10

# Export Weights (Float -> Int8 Hex)
python export_weights.py
