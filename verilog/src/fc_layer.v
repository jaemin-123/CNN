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

    // 파이프라인 제어 신호들
    reg mult_valid_pipe; 
    reg first_pixel_pipe; 
    reg last_pixel_pipe;  

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
                mult_valid_pipe <= 1; 
                
                if (input_cnt == 0) first_pixel_pipe <= 1;
                else                first_pixel_pipe <= 0;
                
                if (input_cnt == 47) last_pixel_pipe <= 1;
                else                 last_pixel_pipe <= 0;

                for(i=0; i<10; i=i+1) begin
                    mult_reg[i] <= data_in * w[i][input_cnt];
                end

                if (input_cnt == 47) input_cnt <= 0;
                else                 input_cnt <= input_cnt + 1;

            end else begin
                mult_valid_pipe <= 0;
                first_pixel_pipe <= 0;
                last_pixel_pipe <= 0;
            end

            // [Stage 2] 누적 (Accumulation)
            if (mult_valid_pipe) begin
                for(i=0; i<10; i=i+1) begin
                    if (first_pixel_pipe) acc[i] <= mult_reg[i];       
                    else                  acc[i] <= acc[i] + mult_reg[i]; 
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
            // 마지막 픽셀 덧셈 직후 트리거
            if (mult_valid_pipe && last_pixel_pipe) stage3_start <= 1;
            else                                    stage3_start <= 0;
        end
    end

    // --------------------------------------------------------
    // 4. Scaling & ArgMax Tree (★수정됨: 2단계 파이프라인 적용)
    //    기존: [곱셈 -> 쉬프트 -> 저장] (1클럭) -> 타이밍 에러 원인
    //    변경: [곱셈 -> 저장] (1클럭) -> [쉬프트 -> 저장] (1클럭)
    // --------------------------------------------------------
    reg signed [31:0] shifted_scores [0:9];
    reg stage3_valid;
    
    // 추가된 레지스터 (곱셈 결과 저장용)
    reg signed [63:0] mult_res_pipe [0:9]; 
    reg stage3_start_d; // Valid 신호 1클럭 지연용
    reg signed [31:0] temp_shifted_val;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            stage3_valid <= 0;
            stage3_start_d <= 0;
            for(i=0; i<10; i=i+1) begin
                shifted_scores[i] <= 0;
                mult_res_pipe[i] <= 0;
            end
        end else begin
            
            // [Step 4-1] 곱셈 먼저 수행 (큰 수 곱셈이라 시간 많이 걸림)
            if (stage3_start) begin
                for(i=0; i<10; i=i+1) begin
                    mult_res_pipe[i] <= acc[i] * $signed(MULTIPLIER);
                end
            end
            stage3_start_d <= stage3_start; // 타이밍 맞춰서 valid 신호 넘김

            // [Step 4-2] 쉬프트 및 Clamping 수행 (다음 클럭)
            stage3_valid <= stage3_start_d;
            
            if (stage3_start_d) begin
                for(i=0; i<10; i=i+1) begin
                    
                    // 저장해둔 곱셈 결과(mult_res_pipe)를 가져와서 쉬프트
                    temp_shifted_val = mult_res_pipe[i] >>> 16;
                    
                    if (temp_shifted_val > 127)       shifted_scores[i] <= 127;
                    else if (temp_shifted_val < -128) shifted_scores[i] <= -128;
                    else                              shifted_scores[i] <= temp_shifted_val;
                end
            end
        end
    end

    // --------------------------------------------------------
    // 5. Tree ArgMax Logic (기존과 동일)
    // --------------------------------------------------------
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