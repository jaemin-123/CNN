`timescale 1ns / 1ps

module fc_layer #(
    parameter DATA_W = 8,
    parameter MULTIPLIER = 200000 
)(
    input  wire clk, rst_n, valid_in,
    input  wire signed [DATA_W-1:0] data_in,
    input  wire [DATA_W*480-1:0] weights_flat,
    output reg valid_out,        
    output reg [3:0] predicted_class
);

    // --------------------------------------------------------
    // 1. Weight Unpacking
    // --------------------------------------------------------
    wire signed [DATA_W-1:0] w [0:9][0:47];
    genvar n, k;
    generate
        for(n=0; n<10; n=n+1) begin : UNPACK_NEURON
            for(k=0; k<48; k=k+1) begin : UNPACK_INPUT
                assign w[n][k] = weights_flat[ (n*48 + k)*DATA_W +: DATA_W ];
            end
        end
    endgenerate

    // --------------------------------------------------------
    // 2. Robust MAC Pipeline (Valid Gating Added)
    // --------------------------------------------------------
    reg [5:0] input_cnt;
    reg signed [31:0] mult_reg [0:9]; 
    reg signed [31:0] acc [0:9];      

    // ★ 안전장치: 파이프라인 제어 신호들
    reg mult_valid_pipe; // 곱셈 결과가 유효한지 표시
    reg first_pixel_pipe; // 현재 곱셈이 첫 번째 픽셀인지 표시
    reg last_pixel_pipe;  // 현재 곱셈이 마지막 픽셀인지 표시

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_cnt <= 0;
            mult_valid_pipe <= 0;
            first_pixel_pipe <= 0;
            last_pixel_pipe <= 0;
            for(i=0; i<10; i=i+1) begin
                mult_reg[i] <= 0;
                acc[i] <= 0;
            end
        end else begin
            // [Stage 1] 곱셈 & 제어 신호 생성
            if (valid_in && input_cnt < 48) begin
                // 1. 데이터 유효성 넘기기
                mult_valid_pipe <= 1; 
                
                // 2. 첫 픽셀 / 마지막 픽셀 정보 넘기기
                if (input_cnt == 0) first_pixel_pipe <= 1;
                else                first_pixel_pipe <= 0;
                
                if (input_cnt == 47) last_pixel_pipe <= 1;
                else                 last_pixel_pipe <= 0;

                // 3. 실제 곱셈 수행
                for(i=0; i<10; i=i+1) begin
                    mult_reg[i] <= data_in * w[i][input_cnt];
                end

                // 4. 카운터 증가
                if (input_cnt == 47) input_cnt <= 0;
                else                 input_cnt <= input_cnt + 1;

            end else begin
                // Valid가 0이면 파이프라인도 멈춤 (쓰레기값 전달 방지)
                mult_valid_pipe <= 0;
                first_pixel_pipe <= 0;
                last_pixel_pipe <= 0;
            end

            // [Stage 2] 누적 (Accumulation) - ★ 핵심 수정 ★
            // mult_valid_pipe가 1일 때만 동작하여 중복 덧셈 방지
            if (mult_valid_pipe) begin
                for(i=0; i<10; i=i+1) begin
                    if (first_pixel_pipe) acc[i] <= mult_reg[i];       // 첫 픽셀은 덮어쓰기 (Reset 효과)
                    else                  acc[i] <= acc[i] + mult_reg[i]; // 나머지는 누적
                end
            end
        end
    end

    // --------------------------------------------------------
    // 3. Post-Processing Trigger
    // --------------------------------------------------------
    reg stage3_start;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) stage3_start <= 0;
        else begin
            // 마지막 픽셀의 덧셈이 끝난 직후(Stage 2 완료)에 트리거
            if (mult_valid_pipe && last_pixel_pipe) stage3_start <= 1;
            else                                    stage3_start <= 0;
        end
    end

    // --------------------------------------------------------
    // 4. Scaling & ArgMax Tree (기존과 동일하지만 트리거 연결 수정)
    // --------------------------------------------------------
    reg signed [31:0] shifted_scores [0:9];
    reg stage3_valid;
    reg signed [63:0] temp_scaled;
    reg signed [31:0] temp_shifted;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            stage3_valid <= 0;
            for(i=0; i<10; i=i+1) shifted_scores[i] <= 0;
        end else begin
            stage3_valid <= stage3_start;
            if (stage3_start) begin
                for(i=0; i<10; i=i+1) begin
                    temp_scaled = acc[i] * $signed(MULTIPLIER);
                    temp_shifted = temp_scaled >>> 16;
                    
                    if (temp_shifted > 127)       shifted_scores[i] <= 127;
                    else if (temp_shifted < -128) shifted_scores[i] <= -128;
                    else                          shifted_scores[i] <= temp_shifted;
                end
            end
        end
    end

    // [Tree ArgMax Logic] (지난번 코드와 동일, 생략 없이 전체 포함)
    reg signed [31:0] l1_val [0:4]; reg [3:0] l1_idx [0:4]; reg l1_valid;
    reg signed [31:0] l2_val [0:2]; reg [3:0] l2_idx [0:2]; reg l2_valid;
    reg signed [31:0] final_max_val;
    reg [3:0]         final_max_idx;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            l1_valid <= 0; l2_valid <= 0; valid_out <= 0; predicted_class <= 0;
        end else begin
            // Level 1
            l1_valid <= stage3_valid;
            if (stage3_valid) begin
                if (shifted_scores[0] >= shifted_scores[1]) begin l1_val[0]<=shifted_scores[0]; l1_idx[0]<=0; end else begin l1_val[0]<=shifted_scores[1]; l1_idx[0]<=1; end
                if (shifted_scores[2] >= shifted_scores[3]) begin l1_val[1]<=shifted_scores[2]; l1_idx[1]<=2; end else begin l1_val[1]<=shifted_scores[3]; l1_idx[1]<=3; end
                if (shifted_scores[4] >= shifted_scores[5]) begin l1_val[2]<=shifted_scores[4]; l1_idx[2]<=4; end else begin l1_val[2]<=shifted_scores[5]; l1_idx[2]<=5; end
                if (shifted_scores[6] >= shifted_scores[7]) begin l1_val[3]<=shifted_scores[6]; l1_idx[3]<=6; end else begin l1_val[3]<=shifted_scores[7]; l1_idx[3]<=7; end
                if (shifted_scores[8] >= shifted_scores[9]) begin l1_val[4]<=shifted_scores[8]; l1_idx[4]<=8; end else begin l1_val[4]<=shifted_scores[9]; l1_idx[4]<=9; end
            end
            // Level 2
            l2_valid <= l1_valid;
            if (l1_valid) begin
                if (l1_val[0] >= l1_val[1]) begin l2_val[0]<=l1_val[0]; l2_idx[0]<=l1_idx[0]; end else begin l2_val[0]<=l1_val[1]; l2_idx[0]<=l1_idx[1]; end
                if (l1_val[2] >= l1_val[3]) begin l2_val[1]<=l1_val[2]; l2_idx[1]<=l1_idx[2]; end else begin l2_val[1]<=l1_val[3]; l2_idx[1]<=l1_idx[3]; end
                l2_val[2]<=l1_val[4]; l2_idx[2]<=l1_idx[4];
            end
            // Level 3 (Final)
            valid_out <= 0;
            if (l2_valid) begin
                if (l2_val[0] >= l2_val[1]) begin final_max_val=l2_val[0]; final_max_idx=l2_idx[0]; end
                else                        begin final_max_val=l2_val[1]; final_max_idx=l2_idx[1]; end
                
                if (l2_val[2] > final_max_val) predicted_class <= l2_idx[2];
                else                           predicted_class <= final_max_idx;
                valid_out <= 1;
            end
        end
    end
endmodule