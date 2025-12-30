`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/12 16:50:28
// Design Name: 
// Module Name: ReLU
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


module relu #(
    parameter DATA_W = 24
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 valid_in,
    input  wire signed [DATA_W-1:0] in,
    output reg                  valid_out,
    output reg signed [DATA_W-1:0] out
);
    localparam signed [DATA_W-1:0] ZERO = {DATA_W{1'b0}};
    
    always @(posedge clk or negedge rst_n) begin
      if(!rst_n) begin
        valid_out <= 1'b0;
        out       <= ZERO;
      end else begin
        valid_out <= valid_in;
        if(valid_in) out <= (in < 0) ? ZERO : in;
      end
    end
endmodule