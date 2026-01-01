`timescale 1ns / 1ps

module single_image_rom (
    input wire clk,
    input wire [9:0] addr,  // 0~783 (784개 픽셀)
    output reg signed [7:0] data_out
);
    // 1장 이미지 (784바이트) 저장 공간
    reg [7:0] memory [0:783];

    initial begin
        // ★ 중요: 갖고 계신 hex 파일 중 하나를 복사해서 "image_1.hex"로 만드세요
        // 혹은 기존 hex 파일을 그대로 쓰되, 처음 784줄만 읽힙니다.
        $readmemh("D:/01_work_verilog/01_CNN/images_100.hex", memory);
    end

    always @(posedge clk) begin
        data_out <= memory[addr];
    end
endmodule