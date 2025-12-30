`timescale 1ns / 1ps

module parallel_to_serial #(
    parameter DATA_W = 8
)(
    input  wire clk,
    input  wire rst_n,
    
    // 병렬 입력 (Layer 2의 결과 3개)
    input  wire signed [DATA_W-1:0] din_0,
    input  wire signed [DATA_W-1:0] din_1,
    input  wire signed [DATA_W-1:0] din_2,
    input  wire vin_0, vin_1, vin_2, // 각 채널의 Valid 신호
    
    // 직렬 출력 (FC Layer로 보낼 것)
    output reg signed [DATA_W-1:0] dout,
    output reg vout
);

    reg signed [DATA_W-1:0] buf_1, buf_2; // 데이터 임시 저장소
    reg [1:0] state; // 순서 제어용 상태 변수

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            vout  <= 0;
            dout  <= 0;
            buf_1 <= 0;
            buf_2 <= 0;
        end else begin
            vout <= 0; // 기본적으로 0 (Pulse)

            // 1. 세 개가 동시에 들어오는 순간 (Layer 2 완료 시점)
            if (vin_0 && vin_1 && vin_2) begin
                vout  <= 1;
                dout  <= din_0; // 첫 번째 놈은 바로 내보냄
                
                buf_1 <= din_1; // 두 번째 놈 저장
                buf_2 <= din_2; // 세 번째 놈 저장
                state <= 1;     // "다음엔 두 번째 놈 보낼 차례야" 라고 기록
            end 
            // 2. 저장해둔 두 번째 놈 발송
            else if (state == 1) begin
                vout  <= 1;
                dout  <= buf_1;
                state <= 2;
            end
            // 3. 저장해둔 세 번째 놈 발송
            else if (state == 2) begin
                vout  <= 1;
                dout  <= buf_2;
                state <= 0; // 다시 대기 상태로
            end
        end
    end

endmodule