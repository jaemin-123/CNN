//`timescale 1ns / 1ps

//module tb_cnn_1000;

//    // ==========================================
//    // Parameters
//    // ==========================================
//    parameter DATA_W = 8;
//    parameter IMG_W  = 28;
//    parameter CLK_PERIOD = 8;
    
//    // ★ 수정됨: 1000개 테스트
//    parameter NUM_TEST = 1000; 

//    reg clk, rst_n, valid_in;
//    reg signed [DATA_W-1:0] data_in;
//    wire fc_done;
//    wire [3:0] final_digit;

//    // DUT 연결
//    cnn_multichannel_top #(.DATA_W(DATA_W), .IMG_W(IMG_W)) dut (
//        .clk(clk), .rst_n(rst_n), .valid_in(valid_in), .data_in(data_in),
//        .fc_done(fc_done), .final_digit(final_digit)
//    );

//    // ★ 수정됨: 메모리 크기 증가 (784 * 1000)
//    reg [DATA_W-1:0] all_images [0 : 784*1000 - 1];
//    reg [7:0]        all_labels [0 : 999];

//    // Clock Generation
//    initial clk = 0;
//    always #(CLK_PERIOD/2) clk = ~clk;

//    integer img_idx, px_idx;
//    integer correct_cnt;
//    integer base_addr;
//    reg [3:0] correct_label;

//    initial begin
//        // ★ 파일명 확인 (경로는 시뮬레이션 환경에 맞춰주세요)
//        $readmemh("raw_images_1000.hex", all_images);
//        $readmemh("labels_1000.hex", all_labels);
        
//        // 초기화
//        rst_n = 0; valid_in = 0; data_in = 0;
//        correct_cnt = 0;

//        #100; rst_n = 1; #20;

//        $display("\n========================================");
//        $display(" Start Testing %0d Images...", NUM_TEST);
//        $display("========================================\n");

//        for (img_idx = 0; img_idx < NUM_TEST; img_idx = img_idx + 1) begin
            
//            // 이미지 바뀔 때마다 리셋 (안전하게)
//            rst_n = 0; #20; rst_n = 1; #20;

//            correct_label = all_labels[img_idx][3:0];
//            base_addr = img_idx * 784;

//            // 픽셀 주입
//            for (px_idx = 0; px_idx < 784; px_idx = px_idx + 1) begin
//                @(negedge clk);
//                valid_in = 1;
//                data_in = all_images[base_addr + px_idx];
//            end

//            @(negedge clk);
//            valid_in = 0;
//            data_in = 0;

//            // 결과 대기
//            wait(fc_done);
//            @(posedge clk);

//            // 채점
//            if (final_digit == correct_label) begin
//                correct_cnt = correct_cnt + 1;
//            end else begin
//                // 틀린 경우 출력
//                $display("Img %0d: FAIL (Pred: %d, True: %d)", img_idx, final_digit, correct_label);
//            end
            
//            // 진행 상황 출력 (100개마다)
//            if ((img_idx + 1) % 100 == 0) begin
//                $display("Process: %0d / %0d done... (Current Acc: %0d %%)", 
//                         img_idx + 1, NUM_TEST, correct_cnt * 100 / (img_idx + 1));
//            end

//            #200; // 다음 이미지 전 딜레이
//        end

//        $display("\n========================================");
//        $display(" Test Finished!");
//        $display(" Total Images: %0d", NUM_TEST);
//        $display(" Correct:      %0d", correct_cnt);
//        // 소수점 출력이 안 되니 정수형으로 대략 계산
//        $display(" Accuracy:      %0d.%0d %%", (correct_cnt * 100 / NUM_TEST), (correct_cnt * 1000 / NUM_TEST) % 10);
//        $display("========================================");
        
//        $finish;
//    end

//endmodule

`timescale 1ns / 1ps

module tb_cnn_10000; // 모듈 이름도 10000으로 변경하면 구분이 쉽습니다

    // ==========================================
    // Parameters
    // ==========================================
    parameter DATA_W = 8;
    parameter IMG_W  = 28;
    parameter CLK_PERIOD = 8;
    
    // ★ 10,000개 테스트 설정
    parameter NUM_TEST = 10000; 

    reg clk, rst_n, valid_in;
    reg signed [DATA_W-1:0] data_in;
    wire fc_done;
    wire [3:0] final_digit;

    // DUT 연결
    cnn_multichannel_top #(.DATA_W(DATA_W), .IMG_W(IMG_W)) dut (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in), .data_in(data_in),
        .fc_done(fc_done), .final_digit(final_digit)
    );

    // ==========================================
    // ★ [중요] 메모리 크기 수정 (10,000개 분량 확보)
    // ==========================================
    // 784픽셀 * 10,000장 = 7,840,000개 주소 필요
    reg [DATA_W-1:0] all_images [0 : 784*10000 - 1]; 
    
    // 정답 라벨 10,000개
    reg [7:0]        all_labels [0 : 9999];

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    integer img_idx, px_idx;
    integer correct_cnt;
    integer base_addr;
    reg [3:0] correct_label;

    initial begin
        // 파일 로드 (업로드해주신 파일명과 일치)
        $display("Loading Hex Files...");
        $readmemh("raw_images_10000.hex", all_images);
        $readmemh("labels_10000.hex", all_labels);
        
        // 초기화
        rst_n = 0; valid_in = 0; data_in = 0;
        correct_cnt = 0;

        #100; rst_n = 1; #20;

        $display("\n========================================");
        $display(" Start Testing %0d Images...", NUM_TEST);
        $display("========================================\n");

        for (img_idx = 0; img_idx < NUM_TEST; img_idx = img_idx + 1) begin
            
            // 이미지 바뀔 때마다 리셋 (안정성을 위해 유지)
            rst_n = 0; #20; rst_n = 1; #20;

            correct_label = all_labels[img_idx][3:0];
            base_addr = img_idx * 784;

            // 픽셀 주입
            for (px_idx = 0; px_idx < 784; px_idx = px_idx + 1) begin
                valid_in = 1;
                data_in = all_images[base_addr + px_idx];
                @(posedge clk); // 데이터 안정성을 위해 posedge 직전에 넣고 대기하거나, 여기서 대기
            end

            valid_in = 0;
            data_in = 0;

            // 결과 대기
            wait(fc_done);
            @(posedge clk);

            // 채점
            if (final_digit == correct_label) begin
                correct_cnt = correct_cnt + 1;
            end else begin
                // 틀린 경우 로그 출력 (너무 많이 출력되면 시뮬레이션 느려지므로 필요시 주석 처리)
                // $display("Img %0d: FAIL (Pred: %d, True: %d)", img_idx, final_digit, correct_label);
            end
            
            // 진행 상황 출력 (1000개 단위로 변경 추천 - 100개는 너무 자주 찍힘)
            if ((img_idx + 1) % 1000 == 0) begin
                $display("Process: %0d / %0d done... (Current Acc: %0.2f %%)", 
                         img_idx + 1, NUM_TEST, (correct_cnt * 100.0) / (img_idx + 1));
            end

            #200; // 다음 이미지 전 딜레이
        end

        $display("\n========================================");
        $display(" Test Finished!");
        $display(" Total Images: %0d", NUM_TEST);
        $display(" Correct     : %0d", correct_cnt);
        $display(" Accuracy    : %0.2f %%", (correct_cnt * 100.0) / NUM_TEST);
        $display("========================================");
        
        $finish;
    end

endmodule