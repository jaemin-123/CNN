`timescale 1ns / 1ps

module conv_3ch_sum_PE #(
    parameter DATA_W = 8,
    parameter ACC_W  = 24
)(
    input  wire clk, rst_n, valid_in,
    
    // [수정] 2D 배열 대신 긴 1D 벡터로 입력받음 (25개 * 8비트 = 200비트)
    // MSB부터 p00, p01 ... 순서로 가정
    input  wire signed [DATA_W*25-1:0] ch0_flat, 
    input  wire signed [DATA_W*25-1:0] ch1_flat,
    input  wire signed [DATA_W*25-1:0] ch2_flat,
    
    // [수정] 가중치도 Wire로 입력받음 (총 75개 * 8비트 = 600비트)
    // 순서: {Ch0_Weights(25), Ch1_Weights(25), Ch2_Weights(25)}
    input  wire signed [DATA_W*75-1:0] weights_flat,

    output reg  signed [ACC_W-1:0] sum_out,
    output reg  valid_out
);

    // 1. 긴 벡터를 다시 5x5 개별 와이어로 분해 (Unpacking)
    wire signed [DATA_W-1:0] w0[0:24];
    wire signed [DATA_W-1:0] w1[0:24];
    wire signed [DATA_W-1:0] w2[0:24];
    
    // 가중치 분해
    wire signed [DATA_W-1:0] k0[0:24];
    wire signed [DATA_W-1:0] k1[0:24];
    wire signed [DATA_W-1:0] k2[0:24];

    genvar i;
    generate
        for(i=0; i<25; i=i+1) begin : UNPACK
            // 입력 이미지 Unpack (25*8 - 1 - i*8) ...
            assign w0[i] = ch0_flat[ (25-i)*DATA_W-1 -: DATA_W ];
            assign w1[i] = ch1_flat[ (25-i)*DATA_W-1 -: DATA_W ];
            assign w2[i] = ch2_flat[ (25-i)*DATA_W-1 -: DATA_W ];
            
            // 가중치 Unpack (Channel 0: 상위 200비트, Ch1: 중간, Ch2: 하위)
            // Weight Flat Indexing: 75 total weights. 
            // Ch0: indices 0~24 (Top bits), Ch1: 25~49, Ch2: 50~74
            assign k0[i] = weights_flat[ (75-i)*DATA_W-1 -: DATA_W ];
            assign k1[i] = weights_flat[ (50-i)*DATA_W-1 -: DATA_W ];
            assign k2[i] = weights_flat[ (25-i)*DATA_W-1 -: DATA_W ];
        end
    endgenerate

    // 2. Convolution 수행
    wire signed [ACC_W-1:0] y0, y1, y2;
    wire v0, v1, v2;

    conv5x5_single_filter #(.DATA_BITS(DATA_W), .SUM_BITS(ACC_W)) conv_ch0 (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .p00(w0[0]), .p01(w0[1]), .p02(w0[2]), .p03(w0[3]), .p04(w0[4]),
        .p10(w0[5]), .p11(w0[6]), .p12(w0[7]), .p13(w0[8]), .p14(w0[9]),
        .p20(w0[10]),.p21(w0[11]),.p22(w0[12]),.p23(w0[13]),.p24(w0[14]),
        .p30(w0[15]),.p31(w0[16]),.p32(w0[17]),.p33(w0[18]),.p34(w0[19]),
        .p40(w0[20]),.p41(w0[21]),.p42(w0[22]),.p43(w0[23]),.p44(w0[24]),
        
        .k00(k0[0]), .k01(k0[1]), .k02(k0[2]), .k03(k0[3]), .k04(k0[4]),
        .k10(k0[5]), .k11(k0[6]), .k12(k0[7]), .k13(k0[8]), .k14(k0[9]),
        .k20(k0[10]),.k21(k0[11]),.k22(k0[12]),.k23(k0[13]),.k24(k0[14]),
        .k30(k0[15]),.k31(k0[16]),.k32(k0[17]),.k33(k0[18]),.k34(k0[19]),
        .k40(k0[20]),.k41(k0[21]),.k42(k0[22]),.k43(k0[23]),.k44(k0[24]),
        .bias(24'sd0), // [수정됨] 0 -> 24'sd0 
        .valid_out(v0), .y(y0)
    );

    conv5x5_single_filter #(.DATA_BITS(DATA_W), .SUM_BITS(ACC_W)) conv_ch1 (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .p00(w1[0]), .p01(w1[1]), .p02(w1[2]), .p03(w1[3]), .p04(w1[4]),
        .p10(w1[5]), .p11(w1[6]), .p12(w1[7]), .p13(w1[8]), .p14(w1[9]),
        .p20(w1[10]),.p21(w1[11]),.p22(w1[12]),.p23(w1[13]),.p24(w1[14]),
        .p30(w1[15]),.p31(w1[16]),.p32(w1[17]),.p33(w1[18]),.p34(w1[19]),
        .p40(w1[20]),.p41(w1[21]),.p42(w1[22]),.p43(w1[23]),.p44(w1[24]),
        
        .k00(k1[0]), .k01(k1[1]), .k02(k1[2]), .k03(k1[3]), .k04(k1[4]),
        .k10(k1[5]), .k11(k1[6]), .k12(k1[7]), .k13(k1[8]), .k14(k1[9]),
        .k20(k1[10]),.k21(k1[11]),.k22(k1[12]),.k23(k1[13]),.k24(k1[14]),
        .k30(k1[15]),.k31(k1[16]),.k32(k1[17]),.k33(k1[18]),.k34(k1[19]),
        .k40(k1[20]),.k41(k1[21]),.k42(k1[22]),.k43(k1[23]),.k44(k1[24]),
        .bias(24'sd0), // [수정됨] 0 -> 24'sd0
        .valid_out(v1), .y(y1)
    );

    conv5x5_single_filter #(.DATA_BITS(DATA_W), .SUM_BITS(ACC_W)) conv_ch2 (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .p00(w2[0]), .p01(w2[1]), .p02(w2[2]), .p03(w2[3]), .p04(w2[4]),
        .p10(w2[5]), .p11(w2[6]), .p12(w2[7]), .p13(w2[8]), .p14(w2[9]),
        .p20(w2[10]),.p21(w2[11]),.p22(w2[12]),.p23(w2[13]),.p24(w2[14]),
        .p30(w2[15]),.p31(w2[16]),.p32(w2[17]),.p33(w2[18]),.p34(w2[19]),
        .p40(w2[20]),.p41(w2[21]),.p42(w2[22]),.p43(w2[23]),.p44(w2[24]),
        
        .k00(k2[0]), .k01(k2[1]), .k02(k2[2]), .k03(k2[3]), .k04(k2[4]),
        .k10(k2[5]), .k11(k2[6]), .k12(k2[7]), .k13(k2[8]), .k14(k2[9]),
        .k20(k2[10]),.k21(k2[11]),.k22(k2[12]),.k23(k2[13]),.k24(k2[14]),
        .k30(k2[15]),.k31(k2[16]),.k32(k2[17]),.k33(k2[18]),.k34(k2[19]),
        .k40(k2[20]),.k41(k2[21]),.k42(k2[22]),.k43(k2[23]),.k44(k2[24]),
        .bias(24'sd0), // [수정됨] 0 -> 24'sd0
        .valid_out(v2), .y(y2)
    );

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sum_out <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= v0;
            if(v0) sum_out <= y0 + y1 + y2;
        end
    end

endmodule