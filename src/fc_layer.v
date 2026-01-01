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

    reg signed [31:0] acc [0:9]; 
    reg [5:0] input_cnt; 
    
    wire signed [DATA_W-1:0] w [0:9][0:47];
    genvar n, k;
    generate
        for(n=0; n<10; n=n+1) begin : UNPACK_NEURON
            for(k=0; k<48; k=k+1) begin : UNPACK_INPUT
                assign w[n][k] = weights_flat[ (n*48 + k)*DATA_W +: DATA_W ];
            end
        end
    endgenerate

    integer i;

    // 결과 계산 Task
    task compute_final_result;
        integer j;
        reg signed [31:0] tmp_acc;
        reg signed [63:0] scaled;
        reg signed [31:0] shifted;
        reg signed [7:0]  score;
        reg signed [7:0]  max_val;
        reg [3:0]         max_idx;
        begin
            max_val = -128;
            max_idx = 0;
            for(j=0; j<10; j=j+1) begin
                if (input_cnt == 0) tmp_acc = data_in * w[j][0];
                else tmp_acc = acc[j] + data_in * w[j][47];

                scaled = tmp_acc * $signed(MULTIPLIER);
                shifted = scaled >>> 16;
                if (shifted > 127) score = 127;
                else if (shifted < -128) score = -128;
                else score = shifted[7:0];

                if (score > max_val) begin
                    max_val = score;
                    max_idx = j[3:0];
                end
            end
            predicted_class <= max_idx;
        end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_cnt <= 0;
            valid_out <= 0;
            predicted_class <= 0;
            for(i=0; i<10; i=i+1) acc[i] <= 0;
        end else begin
            // Latch 방식 (한번 1 되면 유지)
            if (valid_out) valid_out <= 1; 
            else valid_out <= 0;

            if (valid_in) begin
                // ★★★ [DEBUG] 입력 데이터 확인 (첫 번째 이미지 때만) ★★★
                // $time < 1000000 은 시뮬레이션 초반부만 찍겠다는 뜻
//                if ($time < 1000000) begin
//                    // input_cnt가 0~47일 때 들어오는 값 확인
//                    $display("[FC Layer Check] Input[%0d] = %d", input_cnt, $signed(data_in));
//                end

                for(i=0; i<10; i=i+1) begin
                    if (input_cnt == 0) acc[i] <= data_in * w[i][0];
                    else acc[i] <= acc[i] + data_in * w[i][input_cnt]; 
                end

                if (input_cnt == 47) begin
                    compute_final_result();
                    valid_out <= 1; 
                    input_cnt <= 0;
                end else begin
                    input_cnt <= input_cnt + 1;
                end
            end
        end
    end
endmodule