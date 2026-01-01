module line_buffer_5x5 #(
    parameter DATA_BITS = 8,
    parameter WIDTH     = 28
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [DATA_BITS-1:0]     data_in,
    input  wire                     data_valid,

    output reg  [DATA_BITS-1:0]     w00, w01, w02, w03, w04,
    output reg  [DATA_BITS-1:0]     w10, w11, w12, w13, w14,
    output reg  [DATA_BITS-1:0]     w20, w21, w22, w23, w24,
    output reg  [DATA_BITS-1:0]     w30, w31, w32, w33, w34,
    output reg  [DATA_BITS-1:0]     w40, w41, w42, w43, w44,

    output reg                      window_valid
);

    // 버퍼 메모리
    reg [DATA_BITS-1:0] line0 [0:WIDTH-1];
    reg [DATA_BITS-1:0] line1 [0:WIDTH-1];
    reg [DATA_BITS-1:0] line2 [0:WIDTH-1];
    reg [DATA_BITS-1:0] line3 [0:WIDTH-1];

    // 시프트 레지스터
    reg [DATA_BITS-1:0] s0[0:4], s1[0:4], s2[0:4], s3[0:4], s4[0:4];

    integer i;
    reg [10:0] col_cnt; // 넉넉하게 11비트
    reg [10:0] row_cnt;

    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        col_cnt <= 0;
        row_cnt <= 0;
        window_valid <= 0;
        // (레지스터 초기화 생략 가능, FPGA는 자동 0)
      end else if (data_valid) begin
        // 1. 데이터 밀어넣기 (Shift)
        line3[col_cnt] <= line2[col_cnt];
        line2[col_cnt] <= line1[col_cnt];
        line1[col_cnt] <= line0[col_cnt];
        line0[col_cnt] <= data_in;

        for (i=4; i>0; i=i-1) begin
             s0[i] <= s0[i-1]; 
             s1[i] <= s1[i-1]; 
             s2[i] <= s2[i-1]; 
             s3[i] <= s3[i-1]; 
             s4[i] <= s4[i-1];
        end
        s0[0] <= data_in; 
        s1[0] <= line0[col_cnt]; 
        s2[0] <= line1[col_cnt]; 
        s3[0] <= line2[col_cnt]; 
        s4[0] <= line3[col_cnt];

        // 2. [수정] 무식하게 숫자 세기 (노이즈 무시)
        if (col_cnt == WIDTH-1) begin
            col_cnt <= 0;
            // 줄바꿈 할 때만 row 증가
            if (row_cnt < 1000) row_cnt <= row_cnt + 1; 
        end else begin
            col_cnt <= col_cnt + 1;
        end

        // 3. 윈도우 유효성 체크 (4줄 이상 쌓였고, 가로도 4칸 이상 갔으면 OK)
        // 3. ★★★ [핵심 수정] 윈도우 유효성 체크 (범위 제한) ★★★
        // 가로: 0~3번(4개)은 채우는 중 -> 4번부터 27번까지만 유효
        // 세로: 0~3번(4줄)은 채우는 중 -> 4번부터 27번까지만 유효
        if ((row_cnt >= 4 && row_cnt < WIDTH) && (col_cnt >= 4 && col_cnt < WIDTH))
            window_valid <= 1'b1;
        else
            window_valid <= 1'b0; // 범위 밖이면 즉시 차단 (Garbage Free)

      end else begin
        // 데이터가 안 들어올 때는 valid를 끕니다 (안전 제일)
        window_valid <= 1'b0; 
      end
    end

    // 출력 연결
    always @(*) begin
        {w00,w01,w02,w03,w04} = {s4[4],s4[3],s4[2],s4[1],s4[0]};
        {w10,w11,w12,w13,w14} = {s3[4],s3[3],s3[2],s3[1],s3[0]};
        {w20,w21,w22,w23,w24} = {s2[4],s2[3],s2[2],s2[1],s2[0]};
        {w30,w31,w32,w33,w34} = {s1[4],s1[3],s1[2],s1[1],s1[0]};
        {w40,w41,w42,w43,w44} = {s0[4],s0[3],s0[2],s0[1],s0[0]};
    end

endmodule