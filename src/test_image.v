`timescale 1ns / 1ps

module image_rom (
    input wire [9:0] addr, // 0 ~ 783 (28x28 이미지)
    output reg signed [7:0] data_out
);

    always @(*) begin
        case (addr)
            // ============================================================
            // 숫자 7 이미지 데이터 (배경: -128, 글씨: 127)
            // ============================================================
            
            // --- Row 0 ~ Row 4 (거의 다 배경) ---
            // (생략된 인덱스는 default에서 -128로 처리됨)

            // --- 데이터가 있는 부분 (글씨 '7' 모양) ---
            152: data_out = 127; 153: data_out = 127; 154: data_out = 127; 155: data_out = 127; 156: data_out = 127; 157: data_out = 127;
            178: data_out = 127; 179: data_out = 127; 180: data_out = 127; 181: data_out = 127; 182: data_out = 127; 183: data_out = 127; 184: data_out = 127; 185: data_out = 127; 186: data_out = 127; 187: data_out = 127; 188: data_out = 127; 189: data_out = 127;
            206: data_out = 127; 207: data_out = 127; 208: data_out = 127; 209: data_out = 127; 210: data_out = 127; 211: data_out = 127; 212: data_out = 127; 213: data_out = 127; 214: data_out = 127; 215: data_out = 127; 216: data_out = 127; 217: data_out = 127;
            239: data_out = 127; 240: data_out = 127; 241: data_out = 127; 242: data_out = 127; 243: data_out = 127; 244: data_out = 127; 245: data_out = 127;
            267: data_out = 127; 268: data_out = 127; 269: data_out = 127; 270: data_out = 127;
            294: data_out = 127; 295: data_out = 127; 296: data_out = 127; 297: data_out = 127;
            322: data_out = 127; 323: data_out = 127; 324: data_out = 127; 325: data_out = 127;
            350: data_out = 127; 351: data_out = 127; 352: data_out = 127; 353: data_out = 127;
            378: data_out = 127; 379: data_out = 127; 380: data_out = 127; 381: data_out = 127;
            406: data_out = 127; 407: data_out = 127; 408: data_out = 127; 409: data_out = 127;
            434: data_out = 127; 435: data_out = 127; 436: data_out = 127; 437: data_out = 127;
            462: data_out = 127; 463: data_out = 127; 464: data_out = 127; 465: data_out = 127;
            490: data_out = 127; 491: data_out = 127; 492: data_out = 127; 493: data_out = 127;
            518: data_out = 127; 519: data_out = 127; 520: data_out = 127; 521: data_out = 127;
            546: data_out = 127; 547: data_out = 127; 548: data_out = 127; 549: data_out = 127;
            574: data_out = 127; 575: data_out = 127; 576: data_out = 127; 577: data_out = 127;
            602: data_out = 127; 603: data_out = 127; 604: data_out = 127; 605: data_out = 127;
            630: data_out = 127; 631: data_out = 127; 632: data_out = 127; 633: data_out = 127;
            658: data_out = 127; 659: data_out = 127; 660: data_out = 127; 661: data_out = 127;
            686: data_out = 127; 687: data_out = 127; 688: data_out = 127; 689: data_out = 127;
            714: data_out = 127; 715: data_out = 127; 716: data_out = 127;

            // 나머지는 모두 배경색 (-128)
            default: data_out = -8'sd128; 
        endcase
    end
endmodule