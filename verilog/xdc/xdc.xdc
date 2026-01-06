## ----------------------------------------------------------------------------
## 1. System Clock (125 MHz)
## ----------------------------------------------------------------------------
## CNN 가속기가 125MHz에서 동작하도록 클럭을 정의합니다.
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }]; 
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];


## ----------------------------------------------------------------------------
## 2. Reset & Control (Buttons)
## ----------------------------------------------------------------------------
## rst_n (Active Low) -> BTN0 (누르면 1, 평소 0이므로 코드에서 ~btn 처리 필요)
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { rst_n }]; 

## valid_in (Start Trigger) -> BTN1
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { valid_in }];


## ----------------------------------------------------------------------------
## 3. Data Input (Switches) - 임시 연결
## ----------------------------------------------------------------------------
## 보드에 스위치가 4개뿐이라 data_in[3:0]만 연결하고 나머지는 주석 처리합니다.
## (Vivado에서 에러가 나면 나머지를 내부에서 0으로 묶어주는 래퍼가 필요할 수 있습니다.)

set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { data_in[0] }]; # SW0
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { data_in[1] }]; # SW1
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { data_in[2] }]; # SW2
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { data_in[3] }]; # SW3

## 나머지 상위 비트(4~7)는 물리적 핀이 없으므로 XDC에서 할당하지 않습니다.
## (Implementation 과정에서 경고가 뜨거나 0으로 최적화될 수 있습니다.)


## ----------------------------------------------------------------------------
## 4. Result Output (LEDs)
## ----------------------------------------------------------------------------
## 추론 결과 (final_digit) 4비트를 LED에 표시
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { final_digit[0] }]; # LED0
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { final_digit[1] }]; # LED1
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { final_digit[2] }]; # LED2
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { final_digit[3] }]; # LED3

## fc_done (완료 신호) -> RGB LED (초록색)
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { fc_done }]; # LED6_G (RGB)


## ----------------------------------------------------------------------------
## 5. Timing Exceptions
## ----------------------------------------------------------------------------
## LED 출력 타이밍 무시
set_false_path -to [get_ports { final_digit[*] }];
set_false_path -to [get_ports { fc_done }];