`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/12 16:55:11
// Design Name: 
// Module Name: MaxPool
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


module maxpool2x2_core #(
    parameter DATA_W = 24
)(
    input  wire                       clk,
    input  wire                       rst_n,

    input  wire                       valid_in,
    input  wire signed [DATA_W-1:0]   p00, p01,
    input  wire signed [DATA_W-1:0]   p10, p11,

    output reg                        valid_out,
    output reg  signed [DATA_W-1:0]   y
);

    reg signed [DATA_W-1:0] m0, m1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            y         <= {DATA_W{1'b0}};
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                m0 = (p00 > p01) ? p00 : p01;
                m1 = (p10 > p11) ? p10 : p11;
                y  <= (m0 > m1) ? m0 : m1;
            end
        end
    end

endmodule