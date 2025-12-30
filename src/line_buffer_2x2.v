`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
 
// Create Date: 2025/12/16 21:03:34
// Design Name: 
// Module Name: line_buffer_2x2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
 
// Dependencies: 
 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
 
//////////////////////////////////////////////////////////////////////////////////


module line_buffer_2x2 #(
    parameter DATA_BITS = 24,
    parameter DATA_W = 24
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_BITS-1:0] data_in,
    input wire valid_in,
    output reg [DATA_BITS-1:0] p00, p01,
    output reg [DATA_BITS-1:0] p10, p11,
    output reg window_valid
);
    reg [DATA_BITS-1:0] line0 [0:DATA_W-1];

    integer i;
    reg [$clog2(DATA_W)-1:0] col_cnt;
    reg [$clog2(DATA_W)-1:0] row_cnt;
    reg [DATA_BITS-1:0] s0[0:1], s1[0:1];
    
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        col_cnt <= 0;
        row_cnt <= 0;
        window_valid <= 1'b0;
        for (i=0; i<2; i=i+1) begin
          s0[i] <= 0; s1[i] <= 0;
        end
      end else if (valid_in) begin
        // 1) 업데이트 전 값(이전 행들) 탭 확보
//        t0 = line0[col_cnt]; // row-1
//        t1 = line1[col_cnt]; // row-2
//        t2 = line2[col_cnt]; // row-3
//        t3 = line3[col_cnt]; // row-4
    
        // 2) line buffer 갱신 (down shift)
        line0[col_cnt] <= data_in;
    
        // 3) 가로 shift (new sample at index 0)
        for (i=1; i>0; i=i-1) begin
          s0[i] <= s0[i-1];
          s1[i] <= s1[i-1];
        end
    
        s0[0] <= data_in; // current row
        s1[0] <= line0[col_cnt];
    
        // 4) 카운터
        if (col_cnt == DATA_W-1) begin
          col_cnt <= 0;
          row_cnt <= (row_cnt == DATA_W-1) ? 0 : (row_cnt + 1'b1);
        end else begin
          col_cnt <= col_cnt + 1'b1;
        end
    
        // 5) valid (5x5가 꽉 찬 시점)
        window_valid <= (row_cnt >= 1) && (col_cnt >= 1) && row_cnt[0] && col_cnt[0];  // 홀수 row/col에서만;
      end else begin
        window_valid <= 1'b0;
      end
    end

    // --------------------------------------------------
    // Output window (pure wiring)
    // --------------------------------------------------
    always @(*) begin
        {p00,p01} = {s1[1],s1[0]};
        {p10,p11} = {s0[1],s0[0]};
    end
endmodule

//module line_buffer_2x2 #(
//    parameter integer DATA_W = 24,   // 데이터 비트폭( ReLU_out 폭 )
//    parameter integer WIDTH  = 24    // feature map 가로 크기
//)(
//    input  wire                     clk,
//    input  wire                     rst_n,
//    input  wire signed [DATA_W-1:0] data_in,
//    input  wire                     valid_in,

//    output reg  signed [DATA_W-1:0] p00, p01,
//    output reg  signed [DATA_W-1:0] p10, p11,
//    output reg                      window_valid
//);

//    // 이전 줄(row-1) 저장
//    reg signed [DATA_W-1:0] prev_line [0:WIDTH-1];

//    reg [$clog2(WIDTH)-1:0] col_cnt;
//    reg [$clog2(WIDTH)-1:0] row_cnt;

//    reg signed [DATA_W-1:0] prev_left; // (row-1, col-1)
//    reg signed [DATA_W-1:0] curr_left; // (row,   col-1)

//    wire signed [DATA_W-1:0] up_val = prev_line[col_cnt]; // (row-1, col)

//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            col_cnt      <= 5'b00000;
//            row_cnt      <= 5'b00000;
//            prev_left    <= 24'h00000;
//            curr_left    <= 24'h00000;
//            p00          <= 8'h00; p01 <= 8'h00; p10 <= 8'h00; p11 <= 8'h00;
//            window_valid <= 1'b0;
//        end else begin
//            window_valid <= 1'b0;

//            if (valid_in) begin
//                // stride=2 maxpool: (row,col)이 둘 다 홀수일 때 2x2 완성 (0-based)
//                if ((row_cnt != 0) && (col_cnt != 0) &&
//                    (row_cnt[0] == 1'b1) && (col_cnt[0] == 1'b1)) begin
//                    p00          <= prev_left; // (row-1,col-1)
//                    p01          <= up_val;    // (row-1,col)
//                    p10          <= curr_left; // (row,  col-1)
//                    p11          <= data_in;   // (row,  col)
//                    window_valid <= 1'b1;
//                end

//                // left 갱신
//                prev_left <= up_val;
//                curr_left <= data_in;

//                // 다음 row에서 prev로 쓰기 위해 현재값을 저장(덮어써도 OK)
//                prev_line[col_cnt] <= data_in;

//                // 카운터
//                if (col_cnt == WIDTH-1) begin
//                    col_cnt   <= 1'b0;
//                    row_cnt   <= row_cnt + 1'b1;

//                    // ★ row 경계에서 left 초기화(섞임 방지)
//                    prev_left <= 1'b0;
//                    curr_left <= 1'b0;
//                end else begin
//                    col_cnt <= col_cnt + 1'b1;
//                end
//            end
//        end
//    end

//endmodule


module tb_2x2;
    reg clk=0;
    reg rst_n=0;
    reg [7:0] data_in=0;
    reg valid_in=0;

    wire [7:0] p00, p01;
    wire [7:0] p10, p11;
    wire window_valid;
    
    line_buffer_2x2 lb1(
    clk,
    rst_n,
    data_in,
    valid_in,

    p00, p01,
    p10, p11,
    window_valid);
    
    initial begin
        #100 rst_n=1;
        valid_in = 1;
        forever #10 data_in = data_in + 1;
    end
    always #5 clk = ~clk;
endmodule