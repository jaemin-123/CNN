import torch
import argparse
from pathlib import Path

def get_scale(tensor):
    return torch.max(torch.abs(tensor)).item() / 127.0

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--filename', type=str, default='convnet_mnist_quant.th')
    parser.add_argument('--save_dir', default='../saved_models', type=Path)
    args = parser.parse_args()

    print("Loading Model...")
    model_path = args.save_dir / args.filename
    checkpoint = torch.load(model_path, map_location='cpu', weights_only=False)
    state_dict = checkpoint['state_dict']
    
    keys = list(state_dict.keys())
    w_keys = [k for k in keys if 'weight' in k]
    w1 = state_dict[w_keys[0]]; w2 = state_dict[w_keys[1]]; w3 = state_dict[w_keys[2]]
    s_w1 = get_scale(w1); s_w2 = get_scale(w2); s_w3 = get_scale(w3)
    
    # =========================================================
    # 1. Layer 1 Weights
    # =========================================================
    # Shape: [OutCh(3), InCh(1), H(5), W(5)]
    q_w1_tensor = torch.clamp(torch.round(w1 / s_w1), -128, 127).int()

    # ★ 수정 포인트 (v6) ★
    # [0]: Output Channel Flip (필수: Top module 배선 맞춤)
    # [2, 3]: Kernel Flip (필수: Conv 연산)
    # [1]: Input Channel은 건드리지 않음!
    q_w1_tensor = torch.flip(q_w1_tensor, [0, 2, 3]) 
    
    q_w1 = q_w1_tensor.flatten().tolist()

    # =========================================================
    # 2. Layer 2 Weights
    # =========================================================
    # Shape: [OutCh(3), InCh(3), H(5), W(5)]
    q_w2_tensor = torch.clamp(torch.round(w2 / s_w2), -128, 127).int()
    
    # ★ 수정 포인트 (v6) ★
    # [0]: Output Channel Flip (필수)
    # [2, 3]: Kernel Flip (필수)
    # [1]: Input Channel은 Flip 하지 않음! (Dimension 1 제외)
    q_w2_tensor = torch.flip(q_w2_tensor, [0, 2, 3]) 
    
    q_w2 = q_w2_tensor.flatten().tolist()
    
    # =========================================================
    # 3. FC Layer Weights (기존과 동일)
    # =========================================================
    q_w3_tensor = torch.clamp(torch.round(w3 / s_w3), -128, 127).int()
    q_w3_tensor = q_w3_tensor.view(10, 3, 4, 4)
    q_w3_tensor = q_w3_tensor.permute(0, 2, 3, 1) 
    q_w3 = q_w3_tensor.flatten().tolist()
    
    print("Generating Verilog ROM (v6: No Input Channel Flip)...")

    verilog_code = """`timescale 1ns / 1ps

module weight_rom #(
    parameter DATA_W = 8
)(
    output reg [DATA_W*75-1:0]  l1_weights_flat,
    output reg [DATA_W*225-1:0] l2_weights_flat,
    output reg [DATA_W*480-1:0] fc_weights_flat 
);
    reg signed [DATA_W-1:0] l1_mem [0:74];
    reg signed [DATA_W-1:0] l2_mem [0:224];
    reg signed [DATA_W-1:0] fc_mem [0:479]; 
    integer i;

    initial begin
"""
    # L1
    verilog_code += "        // Layer 1 Weights (OutCh Flip, Kernel Flip)\n"
    for i, val in enumerate(q_w1):
        verilog_code += f"        l1_mem[{i}]={val}; "
        if (i+1)%10 == 0: verilog_code += "\n"
        
    # L2
    verilog_code += "\n        // Layer 2 Weights (OutCh Flip, Kernel Flip - NO InCh Flip)\n"
    for i, val in enumerate(q_w2):
        verilog_code += f"        l2_mem[{i}]={val}; "
        if (i+1)%10 == 0: verilog_code += "\n"
        
    # FC
    verilog_code += "\n        // FC Weights (Permuted)\n"
    for i, val in enumerate(q_w3):
        verilog_code += f"        fc_mem[{i}]={val}; "
        if (i+1)%10 == 0: verilog_code += "\n"

    verilog_code += """
        
        // Flattening
        for (i = 0; i < 75; i = i + 1) l1_weights_flat[8*i +: 8] = l1_mem[i];
        for (i = 0; i < 225; i = i + 1) l2_weights_flat[8*i +: 8] = l2_mem[i];
        for (i = 0; i < 480; i = i + 1) fc_weights_flat[8*i +: 8] = fc_mem[i];
    end
endmodule
"""

    with open('../src/weight_rom_final_v6.v', 'w') as f:
        f.write(verilog_code)
    
    print("Done! Created '../src/weight_rom_final_v6.v'")