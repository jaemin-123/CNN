`timescale 1ns / 1ps

module cnn_multichannel_top #(
    parameter DATA_W = 8,
    parameter ACC_W  = 24,
    parameter IMG_W  = 28
)(
    input  wire clk, rst_n, valid_in,
    input  wire signed [DATA_W-1:0] data_in, // (실제로는 ROM 사용으로 안 씀)
    
    // 최종 결과 출력 (FC Layer 결과)
    output wire fc_done,
    output wire [3:0] final_digit
    
//    // (디버깅용) Layer 2 출력
//    output wire signed [DATA_W-1:0] l2_ch0_out, l2_ch1_out, l2_ch2_out,
//    output wire l2_valid_out
);

    // ====================================================================
    // [수정됨] Bias (편향) 값 정의 - 깨진 태그 삭제 완료
    // ====================================================================
    // Layer 1 Bias (3개)
    wire signed [23:0] l1_bias [0:2];
    assign l1_bias[0] = 24'sd1264;
    assign l1_bias[1] = 24'sd3006;
    assign l1_bias[2] = -24'sd2237;

    // Layer 2 Bias (3개)
    wire signed [23:0] l2_bias [0:2];
    assign l2_bias[0] = -24'sd406;
    assign l2_bias[1] = 24'sd504;
    assign l2_bias[2] = 24'sd265;


//    // ====================================================================
//    // 내부 ROM 데이터 처리 로직
//    // ====================================================================
    reg signed [DATA_W-1:0] internal_data;
    reg internal_valid;
//    reg [9:0] pixel_cnt; // 0~783 카운터
//    reg is_sending;
    
//    wire signed [7:0] rom_data;
//    image_rom img_rom_inst ( .addr(pixel_cnt), .data_out(rom_data) );

//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            pixel_cnt <= 0;
//            internal_valid <= 0;
//            internal_data <= 0;
//            is_sending <= 0;
//        end else begin
//            if (valid_in) begin
//                is_sending <= 1;
//                pixel_cnt <= 0;
//            end

//            if (is_sending) begin
//                if (pixel_cnt < 784) begin
//                    internal_valid <= 1;
//                    internal_data  <= rom_data; 
//                    pixel_cnt <= pixel_cnt + 1;
//                end else begin
//                    internal_valid <= 0;
//                    internal_data  <= 0;
//                    is_sending <= 0;
//                    pixel_cnt <= 0;
//                end
//            end else begin
//                internal_valid <= 0;
//            end
//        end
//    end

    // ====================================================================
    // [수정] 내부 ROM 대신 외부 입력(data_in)을 사용하도록 변경
    // ====================================================================
    /* (기존 코드 주석 처리)
    reg [9:0] pixel_cnt;
    reg is_sending;
    wire signed [7:0] rom_data;
    image_rom img_rom_inst ( .addr(pixel_cnt), .data_out(rom_data) );
    
    always @(...) ... (복잡한 카운터 로직) ...
    */

    // [New] 심플하게 외부 입력 연결
    // 테스트벤치에서 valid_in을 784클럭 동안 켜주면서 data_in을 넣어줄 것입니다.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            internal_valid <= 0;
            internal_data  <= 0;
        end else begin
            internal_valid <= valid_in; // 외부 신호 그대로 전달
            internal_data  <= data_in;  // 외부 데이터 그대로 전달
        end
    end
    
    // 가중치 로드
    wire [DATA_W*75-1:0]  l1_w_flat;
    wire [DATA_W*225-1:0] l2_w_flat; 
    
    weight_rom #(.DATA_W(DATA_W)) w_rom (
        .l1_weights_flat(l1_w_flat),
        .l2_weights_flat(l2_w_flat)
    );

    // ====================================================================
    // [Layer 1] Input(1) -> Conv(3) -> Output(3)
    // ====================================================================
    wire [DATA_W*25-1:0] l1_win_flat;
    wire l1_win_valid;
    
    line_buffer_wrapper_5x5 #(.W(IMG_W), .D(DATA_W)) lb_l1 (
        .clk(clk), .rst_n(rst_n), 
        .d_in(internal_data),   // ROM 데이터 연결
        .v_in(internal_valid),  // ROM 유효 신호 연결
        .win_flat_vec(l1_win_flat), .v_out(l1_win_valid)
    );

    wire signed [DATA_W-1:0] l1_pool_out[0:2];
    wire l1_pool_valid[0:2];

    genvar i;
    generate
        for (i=0; i<3; i=i+1) begin : GEN_L1
            wire signed [ACC_W-1:0] conv_y;
            wire conv_valid;
            
            wire signed [DATA_W-1:0] w[0:24];
            genvar j;
            for(j=0; j<25; j=j+1) begin : UPK_L1
                assign w[j] = l1_win_flat[(25-j)*DATA_W-1 -: DATA_W];
            end

            wire signed [DATA_W-1:0] k[0:24];
            for(j=0; j<25; j=j+1) begin : W_L1
                assign k[j] = l1_w_flat[ (75 - i*25 - j)*DATA_W - 1 -: DATA_W ];
            end
            
            conv5x5_single_filter #(.DATA_BITS(DATA_W), .SUM_BITS(ACC_W)) conv_inst (
                .clk(clk), .rst_n(rst_n), .valid_in(l1_win_valid),
                .p00(w[0]), .p01(w[1]), .p02(w[2]), .p03(w[3]), .p04(w[4]),
                .p10(w[5]), .p11(w[6]), .p12(w[7]), .p13(w[8]), .p14(w[9]),
                .p20(w[10]),.p21(w[11]),.p22(w[12]),.p23(w[13]),.p24(w[14]),
                .p30(w[15]),.p31(w[16]),.p32(w[17]),.p33(w[18]),.p34(w[19]),
                .p40(w[20]),.p41(w[21]),.p42(w[22]),.p43(w[23]),.p44(w[24]),
                .k00(k[0]), .k01(k[1]), .k02(k[2]), .k03(k[3]), .k04(k[4]),
                .k10(k[5]), .k11(k[6]), .k12(k[7]), .k13(k[8]), .k14(k[9]),
                .k20(k[10]),.k21(k[11]),.k22(k[12]),.k23(k[13]),.k24(k[14]),
                .k30(k[15]),.k31(k[16]),.k32(k[17]),.k33(k[18]),.k34(k[19]),
                .k40(k[20]),.k41(k[21]),.k42(k[22]),.k43(k[23]),.k44(k[24]),
                .bias(l1_bias[i]), // Bias 연결
                .valid_out(conv_valid), .y(conv_y)
            );

            localparam integer mult_val = (i==0) ? 350896 : (i==1) ? 396032 : 347984;
            wire rq_valid_out;
            wire signed [DATA_W-1:0] rq_y;
            requantizer #(.IN_W(ACC_W), .OUT_W(DATA_W), .MULTIPLIER(mult_val), .SHIFT(16)) rq (
                .clk(clk), .rst_n(rst_n), 
                .valid_in(conv_valid), .data_in(conv_y), 
                .valid_out(rq_valid_out), .data_out(rq_y)
            );

            wire signed [DATA_W-1:0] relu_y;
            wire relu_valid;
            relu #(.DATA_W(DATA_W)) relu_block (
                .clk(clk), .rst_n(rst_n), 
                .valid_in(rq_valid_out), .in(rq_y),
                .valid_out(relu_valid), .out(relu_y)
            );

            wire signed [DATA_W-1:0] mp_p00, mp_p01, mp_p10, mp_p11;
            wire mp_valid_in;
            line_buffer_2x2 #(.DATA_BITS(DATA_W), .DATA_W(24)) lb2 (
                .clk(clk), .rst_n(rst_n), .data_in(relu_y), .valid_in(relu_valid),
                .p00(mp_p00), .p01(mp_p01), .p10(mp_p10), .p11(mp_p11), .window_valid(mp_valid_in)
            );
            maxpool2x2_core #(.DATA_W(DATA_W)) mp (
                .clk(clk), .rst_n(rst_n), .valid_in(mp_valid_in),
                .p00(mp_p00), .p01(mp_p01), .p10(mp_p10), .p11(mp_p11),
                .valid_out(l1_pool_valid[i]), .y(l1_pool_out[i])
            );
        end
    endgenerate

    // ====================================================================
    // [Layer 2] Input(3) -> Conv(3, summed) -> Output(3)
    // ====================================================================
    wire [DATA_W*25-1:0] l2_win_flat_ch0, l2_win_flat_ch1, l2_win_flat_ch2;
    wire l2_v0, l2_v1, l2_v2;
    wire l2_common_valid = l2_v0 & l2_v1 & l2_v2;

    line_buffer_wrapper_5x5 #(.W(12), .D(DATA_W)) lb_l2_c0 (
        .clk(clk), .rst_n(rst_n), .d_in(l1_pool_out[0]), .v_in(l1_pool_valid[0]), 
        .win_flat_vec(l2_win_flat_ch0), .v_out(l2_v0)
    );
    line_buffer_wrapper_5x5 #(.W(12), .D(DATA_W)) lb_l2_c1 (
        .clk(clk), .rst_n(rst_n), .d_in(l1_pool_out[1]), .v_in(l1_pool_valid[1]), 
        .win_flat_vec(l2_win_flat_ch1), .v_out(l2_v1)
    );
    line_buffer_wrapper_5x5 #(.W(12), .D(DATA_W)) lb_l2_c2 (
        .clk(clk), .rst_n(rst_n), .d_in(l1_pool_out[2]), .v_in(l1_pool_valid[2]), 
        .win_flat_vec(l2_win_flat_ch2), .v_out(l2_v2)
    );

    wire signed [DATA_W-1:0] l2_res[0:2];
    wire l2_res_valid[0:2];

    generate
        for (i=0; i<3; i=i+1) begin : GEN_L2
            wire signed [ACC_W-1:0] sum_y;
            wire sum_valid;
            
            wire [DATA_W*75-1:0] current_ch_weights;
            assign current_ch_weights = l2_w_flat[ (225 - i*75)*DATA_W - 1 -: DATA_W*75 ];
            
            conv_3ch_sum_PE #(.DATA_W(DATA_W), .ACC_W(ACC_W)) pe_inst (
                .clk(clk), .rst_n(rst_n), .valid_in(l2_common_valid),
                .ch0_flat(l2_win_flat_ch0),
                .ch1_flat(l2_win_flat_ch1),
                .ch2_flat(l2_win_flat_ch2),
                .weights_flat(current_ch_weights),
                .sum_out(sum_y), .valid_out(sum_valid)
            );
            
            // Bias 더하기
            wire signed [ACC_W-1:0] sum_y_biased;
            assign sum_y_biased = sum_y + l2_bias[i];

            localparam integer mult_val_l2 = (i==0)? 1112220 : (i==1)? 1575645 : 933029;
            wire rq_valid_l2;
            wire signed [DATA_W-1:0] rq_y;
            
            // Requantizer 입력으로 Bias가 더해진 값을 사용
            requantizer #(.IN_W(ACC_W), .OUT_W(DATA_W), .MULTIPLIER(mult_val_l2), .SHIFT(16)) rq_l2 (
                .clk(clk), .rst_n(rst_n), 
                .valid_in(sum_valid), 
                .data_in(sum_y_biased),
                .valid_out(rq_valid_l2), .data_out(rq_y)
            );

            wire signed [DATA_W-1:0] relu_y;
            wire relu_valid;
            relu #(.DATA_W(DATA_W)) relu_block_l2 (
                .clk(clk), .rst_n(rst_n), 
                .valid_in(rq_valid_l2), .in(rq_y),
                .valid_out(relu_valid), .out(relu_y)
            );

            wire signed [DATA_W-1:0] mp_p00, mp_p01, mp_p10, mp_p11;
            wire mp_v;
            line_buffer_2x2 #(.DATA_BITS(DATA_W), .DATA_W(8)) lb2_l2 (
                .clk(clk), .rst_n(rst_n), .data_in(relu_y), .valid_in(relu_valid),
                .p00(mp_p00), .p01(mp_p01), .p10(mp_p10), .p11(mp_p11), .window_valid(mp_v)
            );
            maxpool2x2_core #(.DATA_W(DATA_W)) mp_l2 (
                .clk(clk), .rst_n(rst_n), .valid_in(mp_v),
                .p00(mp_p00), .p01(mp_p01), .p10(mp_p10), .p11(mp_p11),
                .valid_out(l2_res_valid[i]), .y(l2_res[i])
            );
        end
    endgenerate
    
    // 디버깅용 출력
    assign l2_valid_out = l2_res_valid[0];
    assign l2_ch0_out = l2_res[0];
    assign l2_ch1_out = l2_res[1];
    assign l2_ch2_out = l2_res[2];

    // ====================================================================
    // [수정됨] 모듈화된 병렬->직렬 변환기 (깔끔하게 연결만 함)
    // ====================================================================
    wire signed [DATA_W-1:0] fc_in_data;
    wire fc_in_valid;
    
    parallel_to_serial #(.DATA_W(DATA_W)) u_serializer (
        .clk(clk),
        .rst_n(rst_n),
        // Layer 2에서 나온 3개 채널 연결
        .din_0(l2_res[0]), .vin_0(l2_res_valid[0]),
        .din_1(l2_res[1]), .vin_1(l2_res_valid[1]),
        .din_2(l2_res[2]), .vin_2(l2_res_valid[2]),
        // FC Layer로 들어갈 1개 라인 연결
        .dout(fc_in_data),
        .vout(fc_in_valid)
    );

    // FC Layer 연결 수정
    fc_layer #(.DATA_W(DATA_W)) fc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(fc_in_valid), // 수정된 신호 연결
        .data_in(fc_in_data),   // 수정된 신호 연결
        .valid_out(fc_done),
        .predicted_class(final_digit)
    );

endmodule