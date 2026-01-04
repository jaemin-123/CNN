module requantizer #(
    parameter IN_W = 32,
    parameter OUT_W = 8,
    parameter MULTIPLIER = 116,
    parameter SHIFT = 16
)(
    input wire clk, rst_n, valid_in,
    input wire signed [IN_W-1:0] data_in,
    output reg valid_out,
    output reg signed [OUT_W-1:0] data_out
);
    reg signed [IN_W+15:0] scaled_reg; // 파이프라인 레지스터
    reg valid_pipe;
    reg signed [IN_W+15:0] shifted;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 0;
            valid_pipe <= 0;
            data_out <= 0;
            scaled_reg <= 0;
        end else begin
            // Stage 1: 곱셈
            valid_pipe <= valid_in;
            if (valid_in) begin
                scaled_reg <= data_in * $signed(MULTIPLIER);
            end

            // Stage 2: 시프트 및 출력
            valid_out <= valid_pipe;
            if (valid_pipe) begin
                // blocking assignment(=) 사용해서 조합논리 즉시 처리
                
                shifted = scaled_reg >>> SHIFT;
                
                if (shifted > 127)       data_out <= 127;
                else if (shifted < -128) data_out <= -128;
                else                     data_out <= shifted[OUT_W-1:0];
            end
        end
    end
endmodule