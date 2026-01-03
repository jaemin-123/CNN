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

<img width="654" height="61" alt="image" src="https://github.com/user-attachments/assets/f8b3a2a6-f2d7-4e22-a421-9b523d51b32f" />

<img width="301" height="88" alt="image" src="https://github.com/user-attachments/assets/fd12808e-e755-4751-94f5-7f865472dc9a" />

*(Fig 2. Python Simulation comparing 10k set and 1k subset accuracy)*

> **Detailed Analysis:**
> 1.  **Quantization Loss (97.2% → 96.6%):** >     * 실수(Float32)를 8-bit 정수로 변환하는 과정에서 발생한 일반적인 해상도 손실입니다.
> 2.  **Rounding vs Truncation (96.6% → 96.2%):**
>     * Python 시뮬레이션은 정수 변환 시 **반올림(Round-to-nearest)**을 수행했으나, FPGA 하드웨어는 리소스 효율성을 위해 **버림(Truncation)** 방식을 채택했습니다.
>     * 이로 인해 FPGA 결과가 Python Int8 시뮬레이션 대비 약 **0.4%** 낮게 측정되었으나, 이는 설계 의도에 부합하는 허용 가능한 오차 범위입니다.

### 3. FPGA Simulation & Performance
Vivado 시뮬레이션 결과, 1000개의 Test 이미지에 대해 **96.2%**의 정확도를 확인했습니다.

<img width="379" height="87" alt="image" src="https://github.com/user-attachments/assets/c0b12540-ce5a-45c1-8894-f0842de84de0" />
*(Fig 3. FPGA Testbench Log: 96.2% Accuracy & Inference Cycles)*

* **Clock Frequency:** 125 MHz (Target)
* **Inference Latency:** **813 Cycles** / Image
* **Throughput:** 약 **6.5 µs** per Image (@125MHz)

### 4. Resource Utilization
Implementation(Post-Route) 후 자원 사용량입니다. 효율적인 로직 설계를 통해 **DSP 사용량을 최소화(3%)**하고 LUT 위주로 구현했습니다.

<img width="573" height="271" alt="image" src="https://github.com/user-attachments/assets/00e4130f-dd25-4681-86d9-c33c94a248d5" />

<img width="542" height="188" alt="image" src="https://github.com/user-attachments/assets/95fe40ef-a96c-48bd-a4f9-446b75aba645" />
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

### 4. Timing Violation at 125MHz (Intra-Module Pipelining)
* **문제:** 목표 동작 주파수인 125MHz (Period 8ns)에서 Conv PE 및 FC Layer 내부의 긴 조합 회로(MAC 연산 등)로 인해 Setup Time Violation 발생.
* **원인:** 레이어 간 연결이 아닌, **단일 연산 모듈(PE, FC Unit) 내부**의 Critical Path가 한 클럭 주기를 초과함.
* **해결:** 연산기 내부의 곱셈과 덧셈, 활성화 함수(ReLU) 사이에 **Pipeline Register**를 삽입하여 Critical Path를 분할함. 이를 통해 Latency는 소폭 증가했으나 125MHz 동작 타이밍을 안정적으로 확보함.

---


# 🚀 FPGA-based CNN Accelerator: A Post-Training Quantization (PTQ) Approach

![Methodology](https://img.shields.io/badge/Method-PTQ-blueviolet) ![Framework](https://img.shields.io/badge/Train-PyTorch_Float32-orange) ![Hardware](https://img.shields.io/badge/Inference-Verilog_FixedPoint-blue) ![Performance](https://img.shields.io/badge/Freq-125MHz-green)

## 📖 Project Abstract
본 프로젝트는 **PTQ(Post-Training Quantization)** 기법을 활용하여 PyTorch로 학습된 CNN 모델을 FPGA 하드웨어 가속기로 구현한 결과물입니다.

일반적인 Float32 정밀도로 학습된 모델을 **8-bit Integer 기반의 하드웨어(Verilog)**로 이식하는 과정에서 발생하는 정확도 차이(Accuracy Gap)를 분석하고, **Software Simulation 결과와 Hardware Implementation 결과가 오차 범위 내에서 일치**함을 입증했습니다.

특히, 전체 이미지를 버퍼에 저장하지 않고 **Streaming Pipeline** 구조를 설계하여 Latency를 최소화하고 Throughput을 극대화했습니다.

---

## ⚡ Key Feature: Streaming Pipeline Architecture

이 프로젝트의 핵심은 데이터가 멈추지 않고 흐르는 **Fully Pipelined Structure**입니다.

<p align="center">
  <img width="800" alt="Waveform" src="HERE_PUT_YOUR_WAVEFORM_IMAGE_LINK" />
</p>
*(Fig 1. Simulation Waveform showing the Data Flow)*

> **Waveform Analysis (The "Staircase" Effect):**
> 위 파형에서 **신호들이 우하향 계단(↘)**을 그리며 순차적으로 켜지는 것을 볼 수 있습니다.
> 1. `valid_in`: 픽셀 데이터 입력 시작
> 2. `l1_win_valid`: Layer 1 Line Buffer가 채워지고 연산 시작
> 3. `l1_pool_valid`: Layer 1 결과 출력 및 Layer 2 입력
> 4. `l2_common_valid`: Layer 2 연산 시작
> 5. `fc_done`: 최종 추론 완료
>
> 이는 데이터 병목(Bottleneck) 없이 각 레이어가 파이프라인으로 유기적으로 동작하고 있음을 시각적으로 증명합니다.

---

## 🏗 System Architecture

### 1. Model & Quantization (Software)
* **Architecture:** Conv(5x5) → MaxPool → Conv(5x5) → MaxPool → FC (Bias-Free)
* **Quantization Strategy (PTQ):**
    * Weights & Activations: **8-bit Integer**
    * Scaling: Layer-wise shift operations

### 2. Hardware Design (Verilog)
* **Line Buffer Unit:** 5x5 Sliding Window를 실시간 생성하여 메모리 접근 최소화.
* **Intra-Module Pipelining:** 125MHz 동작을 위해 PE(Processing Element) 내부의 Critical Path에 Pipeline Register 삽입.
* **Optimization:** DSP 사용을 최소화하고 LUT 위주의 로직 설계로 자원 효율성 극대화.

---

## 📉 Experimental Results

### 1. Training & Verification (Python)
PyTorch 학습 결과 **97.22%**의 정확도를 달성했으며, FPGA 동작을 모사한 Quantized Simulation(Int8)에서도 **96.60%**의 높은 정확도를 유지했습니다.

<p align="center">
  <img width="842" height="194" alt="Training Log" src="https://github.com/user-attachments/assets/b22f507b-6c67-4807-8a3d-eb17b35fc61a" />
</p>
*(Fig 2. Python Training Log showing 97.22% Test Accuracy)*

### 2. Accuracy Gap Analysis (Software vs Hardware)
하드웨어 설계의 무결성을 증명하기 위해 Python 시뮬레이션(Golden Ref)과 실제 FPGA 출력을 비교했습니다.

| Environment | Precision | Accuracy | Note |
| :--- | :--- | :--- | :--- |
| **Python Baseline** | Float32 | **97.22%** | Target Accuracy |
| **Python Sim (Quantized)** | Int8 | **96.60%** | **Golden Reference** |

<p align="center">
  <img width="654" height="61" alt="Python Verification" src="https://github.com/user-attachments/assets/f8b3a2a6-f2d7-4e22-a421-9b523d51b32f" />
  <br>
  <img width="301" height="88" alt="Python Stats" src="https://github.com/user-attachments/assets/fd12808e-e755-4751-94f5-7f865472dc9a" />
</p>
*(Fig 3. Python Simulation Verification)*

> **Detailed Analysis:**
> 1.  **Quantization Loss (97.2% → 96.6%):**
>     * 실수(Float32)를 8-bit 정수로 변환하는 과정에서 발생한 일반적인 해상도 손실입니다.
> 2.  **Rounding vs Truncation (96.6% → 96.2%):**
>     * Python 시뮬레이션은 정수 변환 시 **반올림(Round-to-nearest)**을 수행했으나, FPGA 하드웨어는 리소스 효율성을 위해 **버림(Truncation)** 방식을 채택했습니다.
>     * 이로 인한 약 **0.4%**의 차이는 설계 의도에 부합하는 허용 가능한 오차 범위입니다.

### 3. FPGA Hardware Performance
실제 FPGA Testbench 시뮬레이션 결과, 1000개의 Test 이미지에 대해 **96.2%**의 정확도를 기록했습니다.

<p align="center">
<img width="379" height="87" alt="FPGA Result" src="https://github.com/user-attachments/assets/c0b12540-ce5a-45c1-8894-f0842de84de0" />
</p>
*(Fig 4. FPGA Simulation Result: 96.2% Accuracy & Cycle Counts)*

* **Latency & Speed:**
    * **Clock Cycles:** 813 Cycles / Image
    * **Inference Time:** **6.5 µs** (@125MHz)

### 4. Resource Utilization
Implementation(Post-Route) 결과입니다. **DSP를 단 6개(3%)만 사용**하면서도 효율적인 CNN 가속 성능을 확보했습니다.

<p align="center">
  <img width="573" height="271" alt="Resource Graph" src="https://github.com/user-attachments/assets/00e4130f-dd25-4681-86d9-c33c94a248d5" />
  <br>
  <img width="542" height="188" alt="Resource Table" src="https://github.com/user-attachments/assets/95fe40ef-a96c-48bd-a4f9-446b75aba645" />
</p>
*(Fig 5. Vivado Implementation Report)*

| Resource | Used | Available | Utilization % |
| :--- | :--- | :--- | :--- |
| **LUT** | 14,643 | 53,200 | **27.52%** |
| **FF** | 12,118 | 106,400 | **11.39%** |
| **DSP** | **6** | 220 | **2.73%** (High Efficiency) |
| **BRAM** | 0.5 | 140 | < 1% |

---

## 🔧 Troubleshooting & Challenges

### 1. Timing Violation at 125MHz
* **문제:** 100MHz에서는 정상 동작하던 회로가 125MHz에서 Setup Time Violation 발생.
* **원인:** Conv PE 및 FC Layer 내부의 MAC 연산 경로(Combinational Logic)가 너무 길어짐.
* **해결:** 연산기 내부(Intra-module)에 **Pipeline Register**를 추가하여 Critical Path를 분할(Retiming). Latency는 소폭 증가했으나 **125MHz Timing Constraint**를 완벽하게 만족.

### 2. FC Layer Garbage Data Issue
* **문제:** Line Buffer가 채워지는 초기 구간(Filling state)에서 부정확한 Valid 신호로 인해 FC Layer에 쓰레기 값이 유입됨.
* **해결:** Valid 신호 생성 로직을 **Data-driven 방식**으로 재설계. Window가 유효한 데이터로 꽉 찼을 때만 정확히 Valid를 High로 띄우도록 수정하여 오동작 방지.

### 3. Vivado Optimization Issue (Resource ~0%)
* **문제:** Behavioral Simulation은 정상이나, Implementation 시 회로가 통째로 삭제되어 리소스가 0에 수렴.
* **원인:** FC Layer 입력부에서 데이터 개수(48개)를 너무 엄격하게 체크하는 카운터 로직 때문에 합성 툴이 "도달 불가능한 로직"으로 오판함.
* **해결:** 엄격한 카운터 조건 대신 **Data-driven(Valid 신호 기반)** 방식으로 설계를 완화(Relaxation)하여 정상 합성 유도.

---

## 🚀 How to Run

### Python
```bash
# Train Model
python _11_train_convnet.py --num_epochs 10
# Export Weights
python export_weights.py
