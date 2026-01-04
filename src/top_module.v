`timescale 1ns / 1ps

module cnn_multichannel_top #(
    parameter DATA_W = 8,
    parameter ACC_W  = 24,
    parameter IMG_W  = 28
)(
    input  wire clk, rst_n, valid_in,
    input  wire [DATA_W-1:0] data_in,
    
    output wire fc_done,
    output wire [3:0] final_digit
    
    // (디버깅용)
//    output wire signed [DATA_W-1:0] l2_ch0_out, l2_ch1_out, l2_ch2_out,
//    output wire l2_valid_out
);

    // ====================================================================
    // Bias (No-Bias Model)
    // ====================================================================
    wire signed [23:0] l1_bias [0:2];
    assign l1_bias[0] = 0; assign l1_bias[1] = 0; assign l1_bias[2] = 0;

    wire signed [23:0] l2_bias [0:2];
    assign l2_bias[0] = 0; assign l2_bias[1] = 0; assign l2_bias[2] = 0;
    
    // ====================================================================
    // ★ [수정] 내부 ROM 연결 (외부 입력 대신 사용)
    // ====================================================================
//    reg  [9:0] rom_addr;
//    wire signed [7:0] rom_data;
    
//    // 이미지 ROM 인스턴스
//    single_image_rom u_test_rom (
//        .clk(clk),
//        .addr(rom_addr),
//        .data_out(rom_data)
//    );

//    reg signed [DATA_W-1:0] internal_data;
//    reg internal_valid;
    
//    // 데이터를 읽어와서 CNN으로 넣어주는 간단한 상태 머신
//    reg [1:0] state;
    
//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            rom_addr <= 0;
//            state <= 0;
//            internal_valid <= 0;
//            internal_data <= 0;
//        end else begin
//            case(state)
//                0: begin // 대기 상태
//                    internal_valid <= 0;
//                    rom_addr <= 0;
//                    if (valid_in) state <= 1; // 버튼 누르면 시작
//                end
                
//                1: begin // 읽기 상태
//                    internal_data <= rom_data; // ROM 데이터 -> CNN 입력
//                    internal_valid <= 1;       // Valid 신호 ON
                    
//                    if (rom_addr < 783) begin
//                        rom_addr <= rom_addr + 1;
//                    end else begin
//                        state <= 0; // 784개 다 넣었으면 끝
//                    end
//                end
//            endcase
//        end
//    end
    
    // ====================================================================
    // 0. Pre-processing Unit (전처리 모듈 추가)
    // ====================================================================
    wire pre_valid;
    wire signed [DATA_W-1:0] pre_data;
    
    preprocessing_unit u_pre (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .raw_data_in(data_in),
        .valid_out(pre_valid),
        .data_out(pre_data)
    );

    // ====================================================================
    // 기존 로직 연결 (입력을 pre_valid, pre_data로 변경)
    // ====================================================================
    
    // Input Buffer
    reg signed [DATA_W-1:0] internal_data;
    reg internal_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            internal_valid <= 0;
            internal_data  <= 0;
        end else begin
            // ★ 수정됨: 외부 입력 대신 전처리 모듈 출력을 받음
            internal_valid <= pre_valid;
            internal_data  <= pre_data; 
        end
    end
    
    // Weight ROM
    wire [DATA_W*75-1:0]  l1_w_flat;
    wire [DATA_W*225-1:0] l2_w_flat;
    wire [DATA_W*480-1:0] fc_w_flat; 
    
    weight_rom #(.DATA_W(DATA_W)) w_rom (
        .l1_weights_flat(l1_w_flat),
        .l2_weights_flat(l2_w_flat),
        .fc_weights_flat(fc_w_flat)
    );

    // Layer 1
    wire [DATA_W*25-1:0] l1_win_flat;
    wire l1_win_valid;
    
    line_buffer_wrapper_5x5 #(.W(IMG_W), .D(DATA_W)) lb_l1 (
        .clk(clk), .rst_n(rst_n), 
        .d_in(internal_data), .v_in(internal_valid),  
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
            wire signed [DATA_W-1:0] k[0:24];
            genvar j;
            for(j=0; j<25; j=j+1) begin : ASSIGN_L1
                assign w[j] = l1_win_flat[(25-j)*DATA_W-1 -: DATA_W];
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
                .bias(l1_bias[i]),
                .valid_out(conv_valid), .y(conv_y)
            );

            wire rq_valid_out;
            wire signed [DATA_W-1:0] rq_y;
            requantizer #(.IN_W(ACC_W), .OUT_W(DATA_W), .MULTIPLIER(119), .SHIFT(16)) rq (
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

    // Layer 2
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
    
    // =========================================================
    // [DEBUG] Layer 2 Input Window Monitor (Ch0만 확인)
    // =========================================================
    // Layer 2의 첫 번째 연산이 수행될 때, 5x5 윈도우 값을 찍어봅니다.
    
//    always @(posedge clk) begin
//        // l2_common_valid가 1이 되는 순간이 연산 시작점입니다.
//        if (l2_common_valid) begin
//            // 너무 많이 찍히면 보기 힘드니까 처음 3번만 찍습니다.
//            if ($time < 50000) begin // 적당한 시간 제한
//                 $display("\n[Verilog L2 Input Window Ch0]");
//                 // 5x5 윈도우는 l2_win_flat_ch0에 평탄화되어 있습니다.
//                 // 가장 최근 값(Row4, Col4)부터 역순으로 들어있을 수 있으니 확인 필요
//                 // 여기서는 5x5 중 가장 중심값(Center)이나 첫 번째 값을 찍어봅시다.
                 
//                 // l2_win_flat_ch0 구조: [p00, p01... p44] 순서인지 확인
//                 // 보통 Line Buffer Wrapper에서 출력할 때 Flatten 합니다.
                 
//                 $display("Window Flat: %h", l2_win_flat_ch0);
//            end
//        end
//    end

    generate
        for (i=0; i<3; i=i+1) begin : GEN_L2
            wire signed [ACC_W-1:0] sum_y;
            wire sum_valid;
            
            wire [DATA_W*75-1:0] current_ch_weights;
            assign current_ch_weights = l2_w_flat[ (225 - i*75)*DATA_W - 1 -: DATA_W*75 ];
//            assign current_ch_weights = l2_w_flat[ (i*75)*DATA_W +: DATA_W*75 ];
            
            conv_3ch_sum_PE #(.DATA_W(DATA_W), .ACC_W(ACC_W)) pe_inst (
                .clk(clk), .rst_n(rst_n), .valid_in(l2_common_valid),
                .ch0_flat(l2_win_flat_ch0),
                .ch1_flat(l2_win_flat_ch1),
                .ch2_flat(l2_win_flat_ch2),
                .weights_flat(current_ch_weights),
                .sum_out(sum_y), .valid_out(sum_valid)
            );
            // ★★★ [DEBUG] 여기가 핵심입니다! ★★★
            // i==0 (첫번째 출력 채널)의 결과만 찍어봅니다.
//            always @(posedge clk) begin
//                if (i == 0 && sum_valid) begin
//                    // 너무 많이 나오면 보기 힘드니까 초반 10개만
//                    if ($time < 500000) 
//                        $display("[Verilog L2 Raw] Val: %d", $signed(sum_y));
//                end
//            end
            
            wire signed [ACC_W-1:0] sum_y_biased;
            assign sum_y_biased = sum_y + l2_bias[i];

            wire rq_valid_l2;
            wire signed [DATA_W-1:0] rq_y;
            
            requantizer #(.IN_W(ACC_W), .OUT_W(DATA_W), .MULTIPLIER(116), .SHIFT(16)) rq_l2 (
                .clk(clk), .rst_n(rst_n), 
                .valid_in(sum_valid), .data_in(sum_y_biased),
                .valid_out(rq_valid_l2), .data_out(rq_y)
            );
            
//            always @(posedge clk) begin
//                // rq_valid_l2가 뜰 때마다 어느 채널에서 무슨 값이 나오는지 확인
//                if (rq_valid_l2) begin
//                    $display("[Verilog L2 Check] Ch %0d | Val: %d", i, $signed(rq_y));
//                end
//            end
            
            // ★★★ [DEBUG] Requantizer 결과 확인 (수정됨) ★★★
//            always @(posedge clk) begin
//                if (i == 0 && rq_valid_l2) begin
//                    // 데이터 64개 정도만 확인
//                    if ($time < 500000) 
//                        $display("[Verilog L2 Requant] Val: %d", $signed(rq_y));
//                end
//            end

            wire signed [DATA_W-1:0] relu_y;
            wire relu_valid;
            relu #(.DATA_W(DATA_W)) relu_block_l2 (
                .clk(clk), .rst_n(rst_n), 
                .valid_in(rq_valid_l2), .in(rq_y),
                .valid_out(relu_valid), .out(relu_y)
            );
            
            // ★★★ [DEBUG] ReLU 출력 확인 (Ch0만) ★★★
//            always @(posedge clk) begin
//                if (i == 0 && relu_valid) begin
//                    if ($time < 500000) 
//                        $display("[Verilog L2 ReLU] Val: %d", $signed(relu_y));
//                end
//            end

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
//            always @(posedge clk) begin
//                if (i == 0) begin
//                    if (sum_valid)    $display("[L2_DEBUG] RAW_SUM: %d", $signed(sum_y));
//                    if (rq_valid_l2)  $display("[L2_DEBUG] REQUANT: %d", $signed(rq_y));
//                    if (relu_valid)   $display("[L2_DEBUG] RELU   : %d", $signed(relu_y));
//                    if (l2_res_valid[0]) $display("[L2_DEBUG] MAXPOOL: %d <--- FC 입구", $signed(l2_res[0]));
//                end
//            end
        end
    endgenerate
    
    // ====================================================================
    // FC Layer (Final)
    // ====================================================================
    wire signed [DATA_W-1:0] fc_raw_data;
    wire fc_raw_valid;
    
    // ====================================================================
    // ★ [DEBUG] P2S 입력 3채널 동시 감시 ★
    // ====================================================================
    
//    always @(posedge clk) begin
//        // 3개 중 하나라도 유효하면 찍어봅니다.
//        if (l2_res_valid[0] || l2_res_valid[1] || l2_res_valid[2]) begin
//             $display("[P2S INPUT Check] Ch0: %d | Ch1: %d | Ch2: %d", 
//                      $signed(l2_res[0]), $signed(l2_res[1]), $signed(l2_res[2]));
//        end
//    end
    
    // 1. Parallel to Serial (단순 버전)
    parallel_to_serial #(.DATA_W(DATA_W)) u_serializer (
        .clk(clk), .rst_n(rst_n),
        .din_0(l2_res[0]), .vin_0(l2_res_valid[0]),
        .din_1(l2_res[1]), .vin_1(l2_res_valid[1]),
        .din_2(l2_res[2]), .vin_2(l2_res_valid[2]),
        .dout(fc_raw_data), .vout(fc_raw_valid)
    );
    
    // ★★★ [DEBUG] MaxPool 결과 (P2S 입력) 확인 ★★★
    // 58(정상)인지 85(비정상)인지 확인하는 결정적 코드
//    always @(posedge clk) begin
//        // l2_res_valid[0]는 MaxPool이 유효한 데이터를 뱉을 때 1이 됩니다.
//        if (l2_res_valid[0]) begin
//             $display("[Verilog MaxPool Out] Ch0 Val: %d", $signed(l2_res[0]));
//        end
//    end

    // ★★★ [FINAL CHECK] FC 입력 데이터 검증 ★★★
    // P2S를 통과해서 FC로 들어가는 최종 데이터
//    reg [31:0] check_cnt;
//    always @(posedge clk or negedge rst_n) begin
//        if(!rst_n) check_cnt <= 0;
//        else if(fc_raw_valid) begin
//            $display("[Verilog FC Input] Index %0d: %d", check_cnt, $signed(fc_raw_data));
//            check_cnt <= check_cnt + 1;
//        end
//    end

    // ★★★ [핵심] 48개 카운터 & 게이트 (Safety Gate) ★★★
    // 쓰레기 데이터가 들어오는 것을 막기 위해 0~47번까지만 문을 열어줍니다.
    
    reg [5:0] fc_input_cnt;
//    reg fc_gated_valid;
//    reg signed [DATA_W-1:0] fc_gated_data; // ★ 데이터 동기화용 레지스터 추가
    
    wire fc_gated_valid;
    wire signed [DATA_W-1:0] fc_gated_data; // ★ 데이터 동기화용 레지스터 추가

//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            fc_input_cnt <= 0;
//            fc_gated_valid <= 0;
//            fc_gated_data <= 0; // 리셋 추가
//        end else begin
//            if (fc_raw_valid && fc_input_cnt < 48) begin
//                fc_gated_valid <= 1;
//                fc_gated_data  <= fc_raw_data; // ★ 데이터도 여기서 캡처 (1클럭 지연됨)
//                fc_input_cnt   <= fc_input_cnt + 1;
//            end else begin
//                fc_gated_valid <= 0;
//                fc_gated_data  <= 0; // (선택사항) 안전하게 0 처리
//            end
//        end
//    end
    assign fc_gated_valid = fc_raw_valid; 
    assign fc_gated_data  = fc_raw_data;

    // 2. FC Layer 연결 수정
    fc_layer #(.DATA_W(DATA_W), .MULTIPLIER(196)) fc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(fc_gated_valid), 
        .data_in(fc_gated_data),     // ★ fc_raw_data 대신 fc_gated_data 연결
        .weights_flat(fc_w_flat), 
        .valid_out(fc_done),
        .predicted_class(final_digit)
    );
    
    // ====================================================================
    // ★ [DEBUG] 파이썬 비교용 데이터 추출 (자동 카운팅 추가)
    // ====================================================================
//    integer f;
//    integer dbg_img_cnt; // 내부에서 이미지 개수를 세는 변수 선언

//    initial begin
//        f = $fopen("verilog_fc_input_dump.txt", "w");
//        dbg_img_cnt = 0;
//    end

//    always @(posedge clk) begin
//        // fc_gated_valid가 1일 때 (FC로 데이터가 들어가는 순간)
//        if (fc_gated_valid) begin
//            // 파일에 기록: 이미지번호, 인덱스(0~47), 값
//            // ★ 중요: fc_raw_data가 아니라 타이밍 맞춘 'fc_gated_data'를 찍어야 합니다.
//            $fwrite(f, "Img_%0d, Idx_%0d, Val_%d\n", dbg_img_cnt, fc_input_cnt, $signed(fc_gated_data));

//            // 만약 마지막 47번 인덱스였다면, 이미지 카운트 증가
//            if (fc_input_cnt == 47) begin
//                dbg_img_cnt = dbg_img_cnt + 1;
//                $fwrite(f, "--------------------------------\n"); // 구분선
//            end
//        end
//    end

endmodule