`timescale 1ns / 1ps

module conv5x5_single_filter #(
    parameter DATA_BITS = 8,
    parameter SUM_BITS = 24 
)(
    input wire clk, rst_n, valid_in,
    // (입력 포트 선언은 기존과 동일하게 유지...)
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

    input wire signed [23:0] bias,
    output wire valid_out, // reg -> wire 변경
    output reg signed [SUM_BITS-1:0] y
);

    // 내부 연산을 위한 배열
    reg signed [SUM_BITS-1:0] mult [0:24]; // 곱셈 결과
    reg signed [SUM_BITS-1:0] row_sum [0:4]; // 행별 합
    
    // Valid 지연 (3클럭 Latency)
    reg [2:0] valid_pipe;
    assign valid_out = valid_pipe[2];

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            y <= 0;
            valid_pipe <= 0;
            // (나머지 레지스터 초기화 생략 가능)
        end else begin
            valid_pipe <= {valid_pipe[1:0], valid_in}; // Shift

            // ------------------------------------------------
            // Stage 1: 곱셈 (Multiplier) - Clock 1
            // ------------------------------------------------
            mult[0] <= p00*k00; mult[1] <= p01*k01; mult[2] <= p02*k02; mult[3] <= p03*k03; mult[4] <= p04*k04;
            mult[5] <= p10*k10; mult[6] <= p11*k11; mult[7] <= p12*k12; mult[8] <= p13*k13; mult[9] <= p14*k14;
            mult[10]<= p20*k20; mult[11]<= p21*k21; mult[12]<= p22*k22; mult[13]<= p23*k23; mult[14]<= p24*k24;
            mult[15]<= p30*k30; mult[16]<= p31*k31; mult[17]<= p32*k32; mult[18]<= p33*k33; mult[19]<= p34*k34;
            mult[20]<= p40*k40; mult[21]<= p41*k41; mult[22]<= p42*k42; mult[23]<= p43*k43; mult[24]<= p44*k44;

            // ------------------------------------------------
            // Stage 2: 행별 덧셈 (Row Adder) - Clock 2
            // ------------------------------------------------
            row_sum[0] <= mult[0] + mult[1] + mult[2] + mult[3] + mult[4];
            row_sum[1] <= mult[5] + mult[6] + mult[7] + mult[8] + mult[9];
            row_sum[2] <= mult[10]+ mult[11]+ mult[12]+ mult[13]+ mult[14];
            row_sum[3] <= mult[15]+ mult[16]+ mult[17]+ mult[18]+ mult[19];
            row_sum[4] <= mult[20]+ mult[21]+ mult[22]+ mult[23]+ mult[24];

            // ------------------------------------------------
            // Stage 3: 최종 합산 + Bias (Final Adder) - Clock 3
            // ------------------------------------------------
            y <= row_sum[0] + row_sum[1] + row_sum[2] + row_sum[3] + row_sum[4] + bias;
        end
    end
endmodule