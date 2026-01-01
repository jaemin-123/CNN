`timescale 1ns / 1ps

module conv5x5_single_filter #(
    parameter DATA_BITS = 8,
    parameter SUM_BITS = 24 // 32비트로 해도 안전함
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,

    // [중요] 모든 입력에 signed 필수!
    input wire signed [DATA_BITS-1:0] p00, p01, p02, p03, p04,
    input wire signed [DATA_BITS-1:0] p10, p11, p12, p13, p14,
    input wire signed [DATA_BITS-1:0] p20, p21, p22, p23, p24,
    input wire signed [DATA_BITS-1:0] p30, p31, p32, p33, p34,
    input wire signed [DATA_BITS-1:0] p40, p41, p42, p43, p44,

    input wire signed [DATA_BITS-1:0] k00, k01, k02, k03, k04,
    input wire signed [DATA_BITS-1:0] k10, k11, k12, k13, k14,
    input wire signed [DATA_BITS-1:0] k20, k21, k22, k23, k24,
    input wire signed [DATA_BITS-1:0] k30, k31, k32, k33, k34,
    input wire signed [DATA_BITS-1:0] k40, k41, k42, k43, k44,

    input wire signed [23:0] bias, // Bias도 signed

    output reg valid_out,
    output reg signed [SUM_BITS-1:0] y
);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid_out <= 0;
            y <= 0;
        end else begin
            valid_out <= valid_in;
            if(valid_in) begin
                // 모든 곱셈과 덧셈을 signed로 처리
                y <= (p00*k00 + p01*k01 + p02*k02 + p03*k03 + p04*k04) +
                     (p10*k10 + p11*k11 + p12*k12 + p13*k13 + p14*k14) +
                     (p20*k20 + p21*k21 + p22*k22 + p23*k23 + p24*k24) +
                     (p30*k30 + p31*k31 + p32*k32 + p33*k33 + p34*k34) +
                     (p40*k40 + p41*k41 + p42*k42 + p43*k43 + p44*k44) +
                     bias;
            end
        end
    end

endmodule