`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/22 11:50:09
// Design Name: 
// Module Name: fc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fc_layer_digit_classifier (
    input clk,
    input valid_in,
    input signed [7:0] feature_in, // MaxPool에서 나온 데이터 하나씩 입력
    output reg [3:0] result_digit, // 최종 판별된 숫자 (0~9)
    output reg result_valid
);
    // 0~9번 클래스에 대한 점수 누적기
    reg signed [31:0] scores [0:9];
    
    // 가중치 ROM (layer_3_weight)
    // 주소: {입력 인덱스, 클래스 번호}
    wire signed [7:0] weight; 
    
    // 들어오는 특징 데이터에 맞춰 점수 계산 (MAC 연산)
    always @(posedge clk) begin
        if (valid_in) begin
            // 모든 클래스(0~9)에 대해 동시에 가중치 곱해서 더하기
            scores[0] <= scores[0] + feature_in * weight_0;
            scores[1] <= scores[1] + feature_in * weight_1;
            scores[2] <= scores[2] + feature_in * weight_2;
            scores[3] <= scores[3] + feature_in * weight_3;
            scores[4] <= scores[4] + feature_in * weight_4;
            scores[5] <= scores[5] + feature_in * weight_5;
            scores[6] <= scores[6] + feature_in * weight_6;
            scores[7] <= scores[7] + feature_in * weight_7;
            scores[8] <= scores[8] + feature_in * weight_8;
            scores[9] <= scores[9] + feature_in * weight_9;
        end
    end
    
    // 모든 입력이 끝나면 가장 큰 점수 찾기 (ArgMax)
    always @(posedge clk) begin
        if (processing_done) begin
            // scores[0] ~ scores[9] 중 최대값의 인덱스를 result_digit에 저장
        end
    end
endmodule
