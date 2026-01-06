`timescale 1ns / 1ps

module tb_latency_real();

    // 1. 파라미터 및 신호 선언
    reg clk;
    reg rst_n;
    reg valid_in;
    reg signed [7:0] data_in;
    
    wire fc_done;
    wire [3:0] final_digit;

    // 2. 측정용 변수 및 파일 처리 변수
    real start_time;
    real end_time;
    real total_cycles;
    integer i;
    integer fd;         // 파일 디스크립터
    integer code;       // 파일 읽기 상태
    reg [7:0] pixel_temp; // 파일에서 읽은 값 임시 저장

    // 3. DUT (Device Under Test) 연결
    cnn_multichannel_top u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .data_in(data_in),
        .fc_done(fc_done),
        .final_digit(final_digit)
    );

    // 4. 클럭 생성 (125MHz = 8ns 주기)
    always #4 clk = ~clk; 

    // 5. 테스트 시나리오
    initial begin
        // ★ [빨간줄 방지] 모든 입력 신호를 0으로 초기화 (가장 중요)
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        data_in = 0;
        pixel_temp = 0;

        // 파일 열기 (Vivado 프로젝트 폴더 -> simulation 폴더 안에 파일이 있어야 함)
        fd = $fopen("raw_images_1000.hex", "r");
        if (fd == 0) begin
            $display("Error: 'raw_images_1000.hex' 파일을 찾을 수 없습니다!");
            $stop;
        end

        // 리셋 시퀀스 (충분한 시간 동안 리셋 유지)
        #100;
        rst_n = 1;
        #20;

        $display("========================================================");
        $display("[TB] Simulation Start: Measuring Inference Latency");
        $display("========================================================");

        // 클럭 엣지에 맞춰서 시작
        @(posedge clk); 
        start_time = $time; // ★ 시작 시간 기록

        // 6. 데이터 입력 (파일에서 첫 번째 이미지 784 픽셀만 읽음)
        valid_in = 1;
        for (i = 0; i < 784; i = i + 1) begin
            // 헥사 파일에서 1줄(1픽셀) 읽기
            code = $fscanf(fd, "%h", pixel_temp); 
            
            // 읽은 데이터 입력
            data_in = pixel_temp;
            
            @(posedge clk);  // 1클럭 대기
        end
        
        // 입력 끝
        valid_in = 0;
        data_in = 0;
        $fclose(fd); // 파일 닫기

        // 7. 결과 대기 (fc_done이 1이 될 때까지)
        wait(fc_done == 1);
        
        // ★ 종료 시간 기록
        end_time = $time; 

        // 8. 결과 계산 및 출력 (기존 포맷 유지)
        // (종료시간 - 시작시간) / 클럭주기(8ns)
        total_cycles = (end_time - start_time) / 8.0;

        $display("========================================================");
        $display("[TB] Inference Completed!");
        $display("--------------------------------------------------------");
        $display("   - Start Time      : %0t ns", start_time);
        $display("   - End Time        : %0t ns", end_time);
        $display("   - Total Time      : %0t ns", (end_time - start_time));
        $display("--------------------------------------------------------");
        $display("★ Total Clock Cycles : %0d cycles", total_cycles);
        $display("========================================================");

        $stop; // 시뮬레이션 종료
    end

endmodule