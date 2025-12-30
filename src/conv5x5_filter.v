`timescale 1ns / 1ps

module conv5x5_single_filter #(
    parameter DATA_BITS = 8,
    parameter SUM_BITS   = 24
)(
    input  wire clk, rst_n, valid_in,
    input  wire signed [DATA_BITS-1:0] p00, p01, p02, p03, p04, p10, p11, p12, p13, p14,
                                       p20, p21, p22, p23, p24, p30, p31, p32, p33, p34,
                                       p40, p41, p42, p43, p44,
    input  wire signed [DATA_BITS-1:0] k00, k01, k02, k03, k04, k10, k11, k12, k13, k14,
                                       k20, k21, k22, k23, k24, k30, k31, k32, k33, k34,
                                       k40, k41, k42, k43, k44,
    input  wire signed [SUM_BITS-1:0]  bias,
    output reg  valid_out,
    output reg  signed [SUM_BITS-1:0]  y
);

    // [Stage 1] 곱셈 결과 레지스터
    reg signed [SUM_BITS-1:0] m00, m01, m02, m03, m04;
    reg signed [SUM_BITS-1:0] m10, m11, m12, m13, m14;
    reg signed [SUM_BITS-1:0] m20, m21, m22, m23, m24;
    reg signed [SUM_BITS-1:0] m30, m31, m32, m33, m34;
    reg signed [SUM_BITS-1:0] m40, m41, m42, m43, m44;
    
    // [Stage 2] 부분 합 레지스터 (새로 추가됨!)
    reg signed [SUM_BITS-1:0] sum_row0, sum_row1, sum_row2, sum_row3, sum_row4;
    
    // Valid 파이프라인 (총 2클럭 지연 필요)
    reg v_stage1, v_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v_stage1 <= 0; v_stage2 <= 0; valid_out <= 0;
            y <= 0;
            // (나머지 레지스터 초기화 생략 - FPGA 자동)
        end else begin
            // -----------------------------------------------------
            // [Stage 1] 곱셈 수행
            // -----------------------------------------------------
            v_stage1 <= valid_in;
            // (입력이 유효하지 않아도 계산은 계속 돌아도 됨, Valid로 제어)
            m00 <= p00 * k00; m01 <= p01 * k01; m02 <= p02 * k02; m03 <= p03 * k03; m04 <= p04 * k04;
            m10 <= p10 * k10; m11 <= p11 * k11; m12 <= p12 * k12; m13 <= p13 * k13; m14 <= p14 * k14;
            m20 <= p20 * k20; m21 <= p21 * k21; m22 <= p22 * k22; m23 <= p23 * k23; m24 <= p24 * k24;
            m30 <= p30 * k30; m31 <= p31 * k31; m32 <= p32 * k32; m33 <= p33 * k33; m34 <= p34 * k34;
            m40 <= p40 * k40; m41 <= p41 * k41; m42 <= p42 * k42; m43 <= p43 * k43; m44 <= p44 * k44;

            // -----------------------------------------------------
            // [Stage 2] 행별 부분 합 (Partial Sum) - 여기서 경로 절단!
            // -----------------------------------------------------
            v_stage2 <= v_stage1;
            sum_row0 <= m00 + m01 + m02 + m03 + m04;
            sum_row1 <= m10 + m11 + m12 + m13 + m14;
            sum_row2 <= m20 + m21 + m22 + m23 + m24;
            sum_row3 <= m30 + m31 + m32 + m33 + m34;
            sum_row4 <= m40 + m41 + m42 + m43 + m44;

            // -----------------------------------------------------
            // [Stage 3] 최종 합 및 Bias 더하기
            // -----------------------------------------------------
            valid_out <= v_stage2;
            if (v_stage2) begin
                y <= sum_row0 + sum_row1 + sum_row2 + sum_row3 + sum_row4 + bias;
            end else begin
                y <= 0;
            end
        end
    end

endmodule