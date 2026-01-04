import torch
import numpy as np
import argparse
from pathlib import Path

def calc_requant_multipliers():
    # 1. 설정
    filename = 'convnet_mnist_quant_new.th'
    save_dir = Path('../saved_models')
    
    print(f"Loading {filename}...")
    model_path = save_dir / filename
    saved_data = torch.load(model_path, map_location='cpu', weights_only=False)
    
    if isinstance(saved_data, dict) and 'state_dict' in saved_data:
        q_dict = saved_data['state_dict']
    else:
        q_dict = saved_data

    # 2. 스케일 값 가져오기 (Vector or Scalar)
    def get_scale(key):
        val = q_dict[key]
        if isinstance(val, np.ndarray):
            val = torch.from_numpy(val).float()
        else:
            val = torch.as_tensor(val).float()
        return val

    # Layer 1
    s_x1 = get_scale('layer_1_s_x_inv')
    s_w1 = get_scale('layer_1_s_w_inv') # 보통 벡터 (3채널)
    
    # Layer 2
    s_x2 = get_scale('layer_2_s_x_inv')
    s_w2 = get_scale('layer_2_s_w_inv') # 보통 벡터
    
    # Layer 3 (FC)
    s_x3 = get_scale('layer_3_s_x_inv')
    s_w3 = get_scale('layer_3_s_w_inv')
    
    # 3. Multiplier 계산 함수
    # Formula: M = (s_in * s_w) / s_out * 2^SHIFT
    # Verilog SHIFT = 16 (고정)
    SHIFT = 16.0
    
    def calc_mult(s_in, s_w, s_out):
        # s_w가 벡터일 경우 평균값 사용 (하드웨어가 Scalar Multiplier만 지원하므로)
        if s_w.numel() > 1:
            s_w_val = s_w.mean().item()
        else:
            s_w_val = s_w.item()
            
        s_in_val = s_in.mean().item() if s_in.numel() > 1 else s_in.item()
        s_out_val = s_out.mean().item() if s_out.numel() > 1 else s_out.item()
        
        real_factor = (s_in_val * s_w_val) / s_out_val
        hw_mult = round(real_factor * (2**SHIFT))
        return hw_mult

    # [Layer 1]
    # rescale_1 = (s_x1 * s_w1) / s_x2
    m1 = calc_mult(s_x1, s_w1, s_x2)
    
    # [Layer 2]
    # rescale_2 = (s_x2 * s_w2) / s_x3
    m2 = calc_mult(s_x2, s_w2, s_x3)
    
    # [FC Layer]
    # FC 출력은 Argmax용이라 스케일이 덜 중요하지만, 내부 오버플로우 방지를 위해 계산
    # 보통 출력 스케일을 1.0(Unscaled) 혹은 입력 스케일 유지로 가정
    # 여기서는 안전하게 (s_x3 * s_w3) / 1.0 * Scaling_Factor 정도로 추정하거나
    # 기존 비율을 유지합니다. 
    # 일단 (s_x3 * s_w3) 자체를 스케일로 보고 적절한 값을 제안합니다.
    # 만약 FC 출력이 8비트라면 s_out을 1.0 근처로 잡아야 함.
    # 임시로 s_out = 0.15 (경험적 수치) 또는 s_x3와 비슷하게 설정
    m3 = calc_mult(s_x3, s_w3, torch.tensor(0.15)) 

    print("\n" + "="*50)
    print(" [Update top_module.v with these NEW Multipliers]")
    print(f" Layer 1 (lb_l1)   : REPLACE 119 WITH -> {m1}")
    print(f" Layer 2 (rq_l2)   : REPLACE 116 WITH -> {m2}")
    print(f" FC Layer (fc_inst): REPLACE 196 WITH -> {m3}")
    print("="*50 + "\n")

if __name__ == '__main__':
    calc_requant_multipliers()