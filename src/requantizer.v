`timescale 1ns / 1ps

module requantizer #(
    parameter IN_W = 32,
    parameter OUT_W = 8,
    parameter MULTIPLIER = 116,
    parameter SHIFT = 16
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire signed [IN_W-1:0] data_in,
    output reg valid_out,
    output reg signed [OUT_W-1:0] data_out
);

    // 곱셈 결과와 쉬프트 결과를 담을 충분히 큰 그릇 (Overflow 방지)
    reg signed [IN_W+15:0] scaled;  
    reg signed [IN_W+15:0] shifted; 

    // 8비트 범위 (-128 ~ 127)
    localparam signed [IN_W+15:0] MAX_VAL = 127;
    localparam signed [IN_W+15:0] MIN_VAL = -128;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 0;
            data_out <= 0;
            scaled <= 0;
            shifted <= 0;
        end else begin
            valid_out <= valid_in;
            
            if (valid_in) begin
                // 1. 곱하기
                scaled = data_in * $signed(MULTIPLIER);
                
                // 2. 나누기 (Arithmetic Shift: 부호 유지)
                shifted = scaled >>> SHIFT;
                
                // 3. ★ 핵심: 자르기 전에 32비트 상태에서 검사 ★
                if (shifted > MAX_VAL) 
                    data_out <= 127;       // 127보다 크면 127로 고정
                else if (shifted < MIN_VAL) 
                    data_out <= -128;      // -128보다 작으면 -128로 고정
                else 
                    data_out <= shifted[OUT_W-1:0]; // 범위 안이면 하위 비트만 통과
            end
        end
    end

endmodule