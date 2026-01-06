# !!학습 다시 해서 수정 필요!!
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
  <img width="1501" height="219" alt="image" src="https://github.com/user-attachments/assets/da564078-a193-4ba8-b41f-06c653d4f79f" />
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

## 🏗 System Architecture & Design Choices

### 1. Model Structure (Software)
* **Architecture:** Conv(5x5) → MaxPool → Conv(5x5) → MaxPool → FC (Bias-Free)
* **Training:** PyTorch Framework (Float32)

### 2. Quantization Strategy (Technical Deep Dive)
본 프로젝트는 하드웨어 효율성을 위해 **Symmetric Quantization** 방식을 채택했습니다.

* **Why -19 ~ 127 Range? (Not -128 ~ 127)**
    * MNIST 데이터는 정규화 후 `0`(배경) ~ `2.82`(글씨)로 양수 쪽으로 치우친 분포(Asymmetry)를 가집니다.
    * 이를 `-128 ~ 127`에 꽉 채워 매핑하려면 **Zero Point Offset** 연산이 필요하여 하드웨어 복잡도가 증가합니다.
    * 따라서 `0`을 기준으로 대칭적인 스케일링을 적용하여 연산을 단순화(Multiplier-only)하였으며, 이로 인해 음수 범위는 `-19`까지만 사용되었습니다.
    
* **Shift Optimization (DSP Efficiency)**
    * 일반적인 SW 프레임워크는 정밀도를 위해 큰 Shift 값(예: 31-bit)을 사용하지만, FPGA의 8-bit 입력 특성을 고려하여 **Shift-16** 수준으로 최적화했습니다.
    * 이를 통해 정확도 손실 없이 DSP 자원 사용량을 획기적으로 줄였습니다.

### 3. Hardware Design (Verilog)
* **Line Buffer Unit:** 5x5 Sliding Window를 실시간 생성하여 메모리 접근 최소화.
* **Intra-Module Pipelining:** 125MHz 동작을 위해 PE(Processing Element) 내부의 Critical Path에 Pipeline Register 삽입.

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
| **FPGA Simulation** | Int8 | **96.20%** | **Final Result** |

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
<img width="379" height="87" alt="image" src="https://github.com/user-attachments/assets/8eb03604-ade8-4096-9622-fd6abb462763" />

</p>
*(Fig 4. FPGA Simulation Result: 96.2% Accuracy & Cycle Counts)*

* **Latency & Speed:**
    * **Clock Cycles:** 815 Cycles / Image
    * **Inference Time:** **6.52 µs** (@125MHz)

### 4. Resource Utilization
Implementation(Post-Route) 결과입니다. **DSP를 단 6개(3%)만 사용**하면서도 효율적인 CNN 가속 성능을 확보했습니다.

<p align="center">
  <img width="577" height="275" alt="image" src="https://github.com/user-attachments/assets/ff48e2b6-efd9-4069-a4d8-2378b4cfb891" />
  <br>
  <img width="577" height="272" alt="image" src="https://github.com/user-attachments/assets/53089b45-74c0-44cb-9be8-81be13baa8e9" />
</p>
*(Fig 5. Vivado Implementation Report)*

| Resource | Used | Available | Utilization % |
| :--- | :--- | :--- | :--- |
| **LUT** | 14,668 | 53,200 | **27.57%** |
| **FF** | 12,136 | 106,400 | **11.41%** |
| **DSP** | **6** | 220 | **2.73%** (High Efficiency) |

---

## 🔧 Troubleshooting & Challenges

### 1. Timing Violation at 125MHz (Intra-Module Pipelining)
* **문제:** 목표 동작 주파수인 125MHz (Period 8ns)에서 Conv PE 및 FC Layer 내부의 긴 조합 회로(MAC 연산 등)로 인해 Setup Time Violation 발생.
* **원인:** 레이어 간 연결이 아닌, **단일 연산 모듈(PE, FC Unit) 내부**의 Critical Path가 한 클럭 주기를 초과함.
* **해결:** 연산기 내부의 곱셈과 덧셈, 활성화 함수(ReLU) 사이에 **Pipeline Register**를 삽입하여 Critical Path를 분할함(Retiming). 이를 통해 Latency는 소폭 증가했으나 125MHz 동작 타이밍을 안정적으로 확보함.

### 2. Vivado Optimization Issue (Resource ~0%)
* **문제:** Behavioral Simulation은 정상이나, Implementation 시 회로가 통째로 삭제되어 리소스가 0에 수렴.
* **원인:** FC Layer 입력부에서 데이터 개수(48개)를 너무 엄격하게 체크하는 카운터 로직 때문에 합성 툴이 "도달 불가능한 로직"으로 오판함.
* **해결:** 엄격한 카운터 조건 대신 **Data-driven(Valid 신호 기반)** 방식으로 설계를 완화(Relaxation)하여 정상 합성 유도.

### 3. FC Layer Garbage Data Issue
* **문제:** Line Buffer가 채워지는 초기 구간(Filling state)에서 부정확한 Valid 신호로 인해 FC Layer에 쓰레기 값이 유입됨.
* **해결:** Valid 신호 생성 로직을 **Data-driven 방식**으로 재설계. Window가 유효한 데이터로 꽉 찼을 때만 정확히 Valid를 High로 띄우도록 수정하여 오동작 방지.
