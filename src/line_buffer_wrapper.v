`timescale 1ns / 1ps
// Helper Wrapper (그대로 유지)
module line_buffer_wrapper_5x5 #(parameter W=28, D=8)(
    input clk, rst_n, input [D-1:0] d_in, input v_in,
    output [D*25-1:0] win_flat_vec, 
    output v_out
);
    wire [D-1:0] w[0:24];
    line_buffer_5x5 #(.DATA_BITS(D), .WIDTH(W)) lb (
        .clk(clk), .rst_n(rst_n), .data_in(d_in), .data_valid(v_in),
        .w00(w[0]), .w01(w[1]), .w02(w[2]), .w03(w[3]), .w04(w[4]),
        .w10(w[5]), .w11(w[6]), .w12(w[7]), .w13(w[8]), .w14(w[9]),
        .w20(w[10]),.w21(w[11]),.w22(w[12]),.w23(w[13]),.w24(w[14]),
        .w30(w[15]),.w31(w[16]),.w32(w[17]),.w33(w[18]),.w34(w[19]),
        .w40(w[20]),.w41(w[21]),.w42(w[22]),.w43(w[23]),.w44(w[24]),
        .window_valid(v_out)
    );
    assign win_flat_vec = {
        w[0], w[1], w[2], w[3], w[4],
        w[5], w[6], w[7], w[8], w[9],
        w[10],w[11],w[12],w[13],w[14],
        w[15],w[16],w[17],w[18],w[19],
        w[20],w[21],w[22],w[23],w[24]
    };
endmodule
