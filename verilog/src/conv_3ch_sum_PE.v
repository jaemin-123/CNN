`timescale 1ns / 1ps

module conv_3ch_sum_PE #(
    parameter DATA_W = 8,
    parameter ACC_W = 24
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    
    input wire [DATA_W*25-1:0] ch0_flat,
    input wire [DATA_W*25-1:0] ch1_flat,
    input wire [DATA_W*25-1:0] ch2_flat,
    input wire [DATA_W*75-1:0] weights_flat,
    
    output reg signed [ACC_W-1:0] sum_out,
    output wire valid_out
);

    // 1. Unpacking (와이어 연결)
    wire signed [DATA_W-1:0] img [0:74]; 
    wire signed [DATA_W-1:0] w   [0:74];

    genvar i;
    generate
        for(i=0; i<25; i=i+1) begin : MAP
            assign img[i]    = ch0_flat[(25-i)*DATA_W-1 -: DATA_W];
            assign img[25+i] = ch1_flat[(25-i)*DATA_W-1 -: DATA_W];
            assign img[50+i] = ch2_flat[(25-i)*DATA_W-1 -: DATA_W];
        end
        for(i=0; i<75; i=i+1) begin : W_MAP
            assign w[i] = weights_flat[(75-i)*DATA_W-1 -: DATA_W];
        end
    endgenerate

    // -------------------------------------------------------------------------
    // ★ 파이프라인 스테이지 (데이터 경로)
    // -------------------------------------------------------------------------
    // Stage 1: 곱셈 (75개) -> Clock 1
    reg signed [ACC_W-1:0] mult_stage [0:74]; 
    
    // Stage 2: 부분 합 (5개씩 묶음 -> 15개) -> Clock 2
    reg signed [ACC_W-1:0] sum_stage1 [0:14]; 
    
    // Stage 3: 채널 합 (채널별 합산 -> 3개) -> Clock 3
    reg signed [ACC_W-1:0] ch_sum [0:2];

    // Stage 4: 최종 합 (Final Sum -> 1개) -> Clock 4
    // (sum_out이 이 역할을 함)

    // -------------------------------------------------------------------------
    // ★ Valid 신호 지연 (데이터 경로인 4클럭에 맞춰야 함!)
    // -------------------------------------------------------------------------
    reg [3:0] valid_pipe; // ★ 기존 [2:0]에서 [3:0]으로 수정 (핵심)
    assign valid_out = valid_pipe[3]; // 4번째 파이프에서 나온 것이 진짜 Valid

    integer k;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sum_out <= 0;
            valid_pipe <= 0;
            for(k=0; k<75; k=k+1) mult_stage[k] <= 0;
            for(k=0; k<15; k=k+1) sum_stage1[k] <= 0;
            ch_sum[0]<=0; ch_sum[1]<=0; ch_sum[2]<=0;
        end else begin
            // Valid Shift Register (4단계 지연)
            valid_pipe <= {valid_pipe[2:0], valid_in};

            // [Stage 1] 곱셈
            for(k=0; k<75; k=k+1) begin
                mult_stage[k] <= img[k] * w[k]; 
            end

            // [Stage 2] 5개씩 묶어서 더하기
            for(k=0; k<15; k=k+1) begin
                sum_stage1[k] <= mult_stage[k*5]   + mult_stage[k*5+1] + 
                                 mult_stage[k*5+2] + mult_stage[k*5+3] + 
                                 mult_stage[k*5+4];
            end

            // [Stage 3] 채널별 합산
            ch_sum[0] <= sum_stage1[0] + sum_stage1[1] + sum_stage1[2] + sum_stage1[3] + sum_stage1[4];
            ch_sum[1] <= sum_stage1[5] + sum_stage1[6] + sum_stage1[7] + sum_stage1[8] + sum_stage1[9];
            ch_sum[2] <= sum_stage1[10]+ sum_stage1[11]+ sum_stage1[12]+ sum_stage1[13]+ sum_stage1[14];

            // [Stage 4] 최종 합산 (여기서 valid_pipe[3]과 타이밍이 맞음)
            sum_out <= ch_sum[0] + ch_sum[1] + ch_sum[2];
        end
    end

endmodule