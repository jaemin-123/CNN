`timescale 1ns / 1ps

module parallel_to_serial #(
    parameter DATA_W = 8
)(
    input  wire clk,
    input  wire rst_n,
    
    // 병렬 입력
    input  wire signed [DATA_W-1:0] din_0, din_1, din_2,
    input  wire vin_0, vin_1, vin_2, 
    
    // 직렬 출력
    output reg signed [DATA_W-1:0] dout, // reg 선언 유지 (좋습니다!)
    output reg vout
);

    // 3개의 독립 FIFO
    reg signed [DATA_W-1:0] q0 [0:63];
    reg signed [DATA_W-1:0] q1 [0:63];
    reg signed [DATA_W-1:0] q2 [0:63];

    reg [5:0] wp0, wp1, wp2; 
    reg [5:0] rp0, rp1, rp2; 
    
    // 데이터 개수 확인용
    wire [5:0] cnt0 = wp0 - rp0;
    wire [5:0] cnt1 = wp1 - rp1;
    wire [5:0] cnt2 = wp2 - rp2;

    reg [1:0] state; 

    // ★★★ [수정] Edge Detector 제거! (단순하게 갑니다) ★★★
    // reg vin_0_prev... 삭제
    // wire v0_pulse... 삭제

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wp0 <= 0; wp1 <= 0; wp2 <= 0;
            rp0 <= 0; rp1 <= 0; rp2 <= 0;
            state <= 0;
            vout  <= 0;
            dout  <= 0;
            // vin_prev 초기화 삭제
        end else begin
            // 1. 쓰기 (Pulse가 아니라 Valid면 무조건 쓴다!)
            // 앞단(MaxPool)이 유효한 데이터를 줄 때 믿고 받습니다.
            if (vin_0) begin q0[wp0] <= din_0; wp0 <= wp0 + 1; end
            if (vin_1) begin q1[wp1] <= din_1; wp1 <= wp1 + 1; end
            if (vin_2) begin q2[wp2] <= din_2; wp2 <= wp2 + 1; end

            // 2. 읽기 (FSM - 기존과 동일)
            vout <= 0; 

            case (state)
                0: begin
                    // 3개 채널 모두 데이터가 1개 이상 있을 때만 시작
                    if (cnt0 > 0 && cnt1 > 0 && cnt2 > 0) begin
                        dout <= q0[rp0];     
                        vout <= 1;
                        rp0  <= rp0 + 1;     
                        state <= 1;          
                    end
                end
                
                1: begin
                    dout <= q1[rp1];        
                    vout <= 1;
                    rp1  <= rp1 + 1;        
                    state <= 2;             
                end

                2: begin
                    dout <= q2[rp2];        
                    vout <= 1;
                    rp2  <= rp2 + 1;        
                    state <= 0;             
                end
            endcase
        end
    end

endmodule