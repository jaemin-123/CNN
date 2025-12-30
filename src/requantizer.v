`timescale 1ns / 1ps

module requantizer #(
    parameter IN_W = 24,
    parameter OUT_W = 8,
    parameter MULTIPLIER = 350896, // 원래 값 복구 (Top에서 덮어쓰겠지만 안전하게)
    parameter SHIFT = 16
)(
    input  wire clk, rst_n, valid_in,
    input  wire signed [IN_W-1:0] data_in,
    
    output reg  valid_out,
    output reg  signed [OUT_W-1:0] data_out
);

    // ============================================================
    // [Stage 1] 입력 레지스터 (Routing Delay 차단)
    // ============================================================
    reg signed [IN_W-1:0] r_data_in;
    reg r_valid_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_data_in  <= 0;
            r_valid_in <= 0;
        end else begin
            r_data_in  <= data_in;
            r_valid_in <= valid_in;
        end
    end

    // ============================================================
    // [Stage 2] 곱셈 레지스터 (Logic Delay의 핵심 - DSP 블록 사용)
    // ============================================================
    reg signed [63:0] r_mult_res; // 곱셈 결과는 넉넉하게 64비트
    reg r_valid_mult;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_mult_res   <= 0;
            r_valid_mult <= 0;
        end else begin
            if (r_valid_in) begin
                // 여기서 막대한 딜레이가 발생하는 곱셈을 수행하고 저장
                r_mult_res   <= r_data_in * $signed(MULTIPLIER);
                r_valid_mult <= 1;
            end else begin
                r_mult_res   <= 0;
                r_valid_mult <= 0;
            end
        end
    end

    // ============================================================
    // [Combinational Logic] 반올림 & 시프트 & 클램핑 (계산만 함)
    // ============================================================
    wire signed [63:0] rounded;
    wire signed [63:0] shifted;
    reg  signed [OUT_W-1:0] clamped_val; // 최종 계산된 값 (아직 레지스터 아님)

    // 1. 반올림 (사용자님 원본 코드 유지)
    generate
        if (SHIFT > 0) begin : GEN_ROUND
            assign rounded = r_mult_res + (1 << (SHIFT - 1));
        end else begin : GEN_NO_ROUND
            assign rounded = r_mult_res;
        end
    endgenerate

    // 2. 시프트
    assign shifted = rounded >>> SHIFT;

    // 3. 클램핑 (Saturate) - 조합 회로로 구성
    always @(*) begin
        if (shifted > 127)      
            clamped_val = 8'sd127;
        else if (shifted < -128) 
            clamped_val = -8'sd128;
        else                     
            clamped_val = shifted[OUT_W-1:0];
    end

    // ============================================================
    // [Stage 3] 출력 레지스터 (최종 결과 내보내기)
    // ============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 0;
            valid_out <= 0;
        end else begin
            // 계산된 클램핑 값을 레지스터에 담아서 출력 (타이밍 확보)
            if (r_valid_mult) begin
                data_out  <= clamped_val;
                valid_out <= 1;
            end else begin
                data_out  <= 0;
                valid_out <= 0;
            end
        end
    end

endmodule