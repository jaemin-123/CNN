# 1. PYTHON 학습모델(실수) 정답률(학습데이터, 검증데이터)
## 학습시 정답률
<img width="494" height="243" alt="image" src="https://github.com/user-attachments/assets/9fc5f1a3-b509-438b-bfd1-182c8801f916" />

<img width="842" height="194" alt="image" src="https://github.com/user-attachments/assets/b22f507b-6c67-4807-8a3d-eb17b35fc61a" />


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


# 🚀 FPGA-based MNIST CNN Accelerator

![Verilog](https://img.shields.io/badge/Verilog-HDL-blue) ![Python](https://img.shields.io/badge/Python-PyTorch-yellow) ![Vivado](https://img.shields.io/badge/Tool-Vivado-green)

## 📝 Project Overview
이 프로젝트는 **Python(PyTorch)**으로 학습된 CNN 모델을 **Verilog HDL**을 사용하여 FPGA 상에서 하드웨어로 직접 구현한 결과물입니다.
MNIST 손글씨 숫자 데이터를 인식하며, 외부 IP(Intellectual Property)를 사용하지 않고 **Line Buffer, Convolution PE, Fully Connected Layer** 등을 직접 설계하여 **Streaming Architecture**를 구현했습니다.

* **Target Device:** Xilinx FPGA (Zynq / Artix-7)
* **Input Data:** 28x28 Grayscale Image (Serial Input)
* **Architecture:** 2-Layer CNN + 1 FC Layer
* **Performance:** * Inference Latency: ~1,000 Cycles/Image (approx. 8µs @ 125MHz)
  * Hardware Accuracy: ~96.2% (Python Reference: 97.2%)

---

## 🏗 System Architecture

### 1. Software (Model Training)
* **Framework:** PyTorch
* **Network Structure:**
  * `Input`: 28x28
  * `Conv1`: 5x5 Kernel, 3 Channels, ReLU, MaxPool(2x2)
  * `Conv2`: 5x5 Kernel, 3 Channels, ReLU, MaxPool(2x2)
  * `FC Layer`: 48 Inputs → 10 Outputs
* **Quantization:** 학습된 Float32 가중치(Weight)와 Bias를 Fixed-point(Integer) 포맷으로 변환하여 `.hex` 파일로 추출.

### 2. Hardware (Verilog Design)
이미지를 메모리에 저장하지 않고 픽셀이 들어오는 즉시 처리하는 **Streaming Pipeline** 구조를 채택했습니다.

* **Line Buffer Unit:** 5x5 Convolution을 위해 입력 스트림을 버퍼링하여 Sliding Window를 생성.
* **Processing Element (PE):** 병렬 MAC(Multiply-Accumulate) 연산 수행.
* **Requantizer:** 연산 결과(Accumulation)를 다음 레이어 입력 비트 폭에 맞춰 Scaling (Bit Shift & Truncation).
* **FC Controller:** 직렬화된 데이터를 받아 최종 Class Score를 계산.

---

## 🔧 Troubleshooting & Challenges (Key Highlights)

프로젝트 진행 중 겪었던 주요 기술적 난관과 해결 과정입니다.

### 1. FC Layer Garbage Data Issue (Valid Signal Timing)
* **문제 (Problem):** Convolution과 Pooling을 거친 데이터가 FC Layer로 진입할 때, 유효하지 않은 데이터(Garbage)가 섞여 들어가는 현상 발생. 이로 인해 특정 이미지에서 오답률이 급격히 상승함.
* **원인 (Cause):** 앞단 **Line Buffer**에서 Sliding Window가 채워지는 초기 구간(Filling State)이나 행(Row)이 바뀔 때, `valid` 신호 제어가 정밀하지 않아 쓰레기 값을 유효한 데이터인 것처럼 출력하고 있었음.
* **해결 (Solution):** FC Layer 입구에 필터를 다는 임시방편 대신, **Line Buffer의 Output Control Logic을 근본적으로 수정**함. Window 내 데이터가 모두 유효할 때만 정확히 `valid`가 High가 되도록 상태 머신을 개선하여 FC Layer로 깨끗한 데이터만 전달되도록 함.

### 2. Vivado Synthesis Optimization Issue (Resource Usage ~0%)
* **문제 (Problem):** Behavioral Simulation은 완벽하게 동작했으나, 실제 FPGA Implementation을 수행하면 **LUT/FF 사용량이 거의 0%**로 나오고 회로가 사라지는 현상 발생.
* **원인 (Cause):** FC Layer 입력부에서 데이터 정합성을 맞추기 위해 **"정확히 48개의 데이터만 카운팅하여 받음"**과 같이 조건을 너무 **엄격(Strict)**하게 설정함. 합성 툴(Synthesis Tool)이 정적 분석 과정에서 특정 신호 도달이 불가능하다고 판단하여, FC Layer 전체를 "사용되지 않는 로직(Unused Logic)"으로 간주하고 삭제(Optimization)해버림.
* **해결 (Solution):** 엄격한 카운터 조건 대신, 앞단에서 넘어오는 **Valid 신호 흐름(Data-driven)에 의존**하도록 설계를 유연하게 변경(Relaxation). 수정 후 정상적으로 리소스가 할당되고 비트스트림이 생성됨.

### 3. Accuracy Drop (Quantization Error)
* **현상:** Python 모델(97.2%) 대비 FPGA 시뮬레이션 정확도가 약 0.5% 낮음.
* **결정:** Verilog 구현 시 복잡한 반올림(Rounding) 로직 대신 **단순 버림(Truncation)** 방식을 사용함. 0.5%의 정확도 손실은 하드웨어 리소스 절약과 타이밍 마진 확보를 위한 **Trade-off**로 판단하여 현재 구조를 유지함.

---

## 📊 Results

### Simulation Waveform
*(여기에 Vivado 시뮬레이션 파형 이미지를 캡처해서 넣으면 좋습니다)*

### Resource Utilization
* **LUT:** (Insert Value)
* **FF:** (Insert Value)
* **BRAM:** (Insert Value)
* **DSP:** (Insert Value)

---
