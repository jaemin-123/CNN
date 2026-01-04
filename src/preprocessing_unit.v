`timescale 1ns / 1ps

module preprocessing_unit (
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    input  wire [7:0] raw_data_in, // 0 ~ 255
    
    output reg  valid_out,
    output reg  signed [7:0] data_out // -19 ~ 127
);

    reg [15:0] mult_result;
    reg valid_stage1; // ★ 박자를 맞추기 위한 중간 Valid 레지스터 추가

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 0;
            valid_out    <= 0;
            mult_result  <= 0;
            data_out     <= 0;
        end else begin
            // [Stage 1] 곱셈 수행
            // valid_in 신호도 같이 한 박자 쉬게 함 (valid_stage1에 저장)
            mult_result  <= raw_data_in * 147;
            valid_stage1 <= valid_in; 
            
            // [Stage 2] 뺄셈 수행 (출력)
            // 데이터가 나올 때 valid_stage1을 valid_out으로 내보냄 -> 2클럭 지연으로 싱크 맞음
            data_out  <= mult_result[15:8] - 8'd19;
            valid_out <= valid_stage1; 
        end
    end

endmodule