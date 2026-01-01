`timescale 1ns / 1ps

module conv_3ch_sum_PE #(
    parameter DATA_W = 8,
    parameter ACC_W = 24
)(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    
    // 3개 채널 입력 (벡터 형태)
    input wire [DATA_W*25-1:0] ch0_flat,
    input wire [DATA_W*25-1:0] ch1_flat,
    input wire [DATA_W*25-1:0] ch2_flat,
    
    // 가중치 (75개)
    input wire [DATA_W*75-1:0] weights_flat,
    
    output reg signed [ACC_W-1:0] sum_out,
    output reg valid_out
);

    // 내부 연산용 배열 (Signed)
    wire signed [DATA_W-1:0] img0[0:24];
    wire signed [DATA_W-1:0] img1[0:24];
    wire signed [DATA_W-1:0] img2[0:24];
    wire signed [DATA_W-1:0] w[0:74]; // 3ch * 25 = 75

    genvar i;
    generate
        // 입력 Unpacking
        for(i=0; i<25; i=i+1) begin : UNPACK_IMG
            assign img0[i] = ch0_flat[(25-i)*DATA_W-1 -: DATA_W];
            assign img1[i] = ch1_flat[(25-i)*DATA_W-1 -: DATA_W];
            assign img2[i] = ch2_flat[(25-i)*DATA_W-1 -: DATA_W];
        end
        // 가중치 Unpacking
        for(i=0; i<75; i=i+1) begin : UNPACK_W
            assign w[i] = weights_flat[(75-i)*DATA_W-1 -: DATA_W];
        end
    endgenerate

    reg signed [ACC_W-1:0] acc0, acc1, acc2;
    reg valid_in_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid_out <= 0;
            sum_out <= 0;
            acc0 <= 0; acc1 <= 0; acc2 <= 0;
        end else begin
            valid_out <= valid_in;
            if(valid_in) begin
                // 각 채널별 MAC 연산 (하드코딩 for loop Unrolling)
                acc0 = (img0[0]*w[0]) + (img0[1]*w[1]) + (img0[2]*w[2]) + (img0[3]*w[3]) + (img0[4]*w[4]) +
                       (img0[5]*w[5]) + (img0[6]*w[6]) + (img0[7]*w[7]) + (img0[8]*w[8]) + (img0[9]*w[9]) +
                       (img0[10]*w[10])+(img0[11]*w[11])+(img0[12]*w[12])+(img0[13]*w[13])+(img0[14]*w[14]) +
                       (img0[15]*w[15])+(img0[16]*w[16])+(img0[17]*w[17])+(img0[18]*w[18])+(img0[19]*w[19]) +
                       (img0[20]*w[20])+(img0[21]*w[21])+(img0[22]*w[22])+(img0[23]*w[23])+(img0[24]*w[24]);

                acc1 = (img1[0]*w[25]) + (img1[1]*w[26]) + (img1[2]*w[27]) + (img1[3]*w[28]) + (img1[4]*w[29]) +
                       (img1[5]*w[30]) + (img1[6]*w[31]) + (img1[7]*w[32]) + (img1[8]*w[33]) + (img1[9]*w[34]) +
                       (img1[10]*w[35])+(img1[11]*w[36])+(img1[12]*w[37])+(img1[13]*w[38])+(img1[14]*w[39]) +
                       (img1[15]*w[40])+(img1[16]*w[41])+(img1[17]*w[42])+(img1[18]*w[43])+(img1[19]*w[44]) +
                       (img1[20]*w[45])+(img1[21]*w[46])+(img1[22]*w[47])+(img1[23]*w[48])+(img1[24]*w[49]);

                acc2 = (img2[0]*w[50]) + (img2[1]*w[51]) + (img2[2]*w[52]) + (img2[3]*w[53]) + (img2[4]*w[54]) +
                       (img2[5]*w[55]) + (img2[6]*w[56]) + (img2[7]*w[57]) + (img2[8]*w[58]) + (img2[9]*w[59]) +
                       (img2[10]*w[60])+(img2[11]*w[61])+(img2[12]*w[62])+(img2[13]*w[63])+(img2[14]*w[64]) +
                       (img2[15]*w[65])+(img2[16]*w[66])+(img2[17]*w[67])+(img2[18]*w[68])+(img2[19]*w[69]) +
                       (img2[20]*w[70])+(img2[21]*w[71])+(img2[22]*w[72])+(img2[23]*w[73])+(img2[24]*w[74]);
                
                sum_out <= acc0 + acc1 + acc2;
            end
        end
    end

endmodule