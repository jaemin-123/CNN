`timescale 1ns / 1ps

module fc_layer #(
    parameter DATA_W = 8,
    parameter ACC_W  = 32,
    parameter IN_NODES = 48,
    parameter OUT_NODES = 10
)(
    input  wire clk,
    input  wire rst_n,
    
    // 이전 Layer 데이터
    input  wire valid_in,
    input  wire signed [DATA_W-1:0] data_in,
    
    // 최종 결과
    output reg valid_out,
    output reg [3:0] predicted_class
);

    // --------------------------------------------------------
    // 1. 입력 버퍼링
    // --------------------------------------------------------
    reg signed [DATA_W-1:0] input_buffer [0:IN_NODES-1];
    reg [5:0] in_cnt;
    reg buffering_done;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_cnt <= 0;
            buffering_done <= 0;
        end else if (valid_in && !buffering_done) begin
            input_buffer[in_cnt] <= data_in;
            if (in_cnt == IN_NODES - 1) begin
                buffering_done <= 1;
            end else begin
                in_cnt <= in_cnt + 1;
            end
        end else if (valid_out) begin
            in_cnt <= 0;
            buffering_done <= 0;
        end
    end

    // --------------------------------------------------------
    // 2. 가중치 함수 (이전과 동일)
    // --------------------------------------------------------
    function signed [7:0] get_weight(input integer out_idx, input integer in_idx);
        integer addr;
        begin
            addr = out_idx * IN_NODES + in_idx;
            case (addr)
                // --- Digit 0 ---
                0: get_weight = -30; 1: get_weight = 57; 2: get_weight = 27; 3: get_weight = 102; 4: get_weight = -90; 5: get_weight = -114; 6: get_weight = -127; 7: get_weight = 122; 8: get_weight = -102; 9: get_weight = -127; 
                10: get_weight = 44; 11: get_weight = -59; 12: get_weight = 60; 13: get_weight = 78; 14: get_weight = -90; 15: get_weight = -1; 16: get_weight = -83; 17: get_weight = 116; 18: get_weight = -11; 19: get_weight = -7; 
                20: get_weight = -60; 21: get_weight = -86; 22: get_weight = 26; 23: get_weight = 45; 24: get_weight = -119; 25: get_weight = -9; 26: get_weight = -40; 27: get_weight = 2; 28: get_weight = 11; 29: get_weight = 89; 
                30: get_weight = 33; 31: get_weight = -127; 32: get_weight = -28; 33: get_weight = -47; 34: get_weight = -127; 35: get_weight = 59; 36: get_weight = -17; 37: get_weight = -9; 38: get_weight = 51; 39: get_weight = 13; 
                40: get_weight = -58; 41: get_weight = 9; 42: get_weight = 16; 43: get_weight = -32; 44: get_weight = 8; 45: get_weight = 43; 46: get_weight = -42; 47: get_weight = 38; 
                // --- Digit 1 ---
                48: get_weight = 127; 49: get_weight = -32; 50: get_weight = -55; 51: get_weight = -31; 52: get_weight = 29; 53: get_weight = -37; 54: get_weight = -16; 55: get_weight = 6; 56: get_weight = -2; 57: get_weight = -60; 
                58: get_weight = 84; 59: get_weight = 53; 60: get_weight = 33; 61: get_weight = -17; 62: get_weight = -3; 63: get_weight = 40; 64: get_weight = 11; 65: get_weight = 74; 66: get_weight = 0; 67: get_weight = -5; 
                68: get_weight = -13; 69: get_weight = 44; 70: get_weight = 9; 71: get_weight = -69; 72: get_weight = -61; 73: get_weight = 2; 74: get_weight = -86; 75: get_weight = 80; 76: get_weight = 37; 77: get_weight = 33; 
                78: get_weight = 11; 79: get_weight = -68; 80: get_weight = -109; 81: get_weight = 49; 82: get_weight = -69; 83: get_weight = -34; 84: get_weight = 27; 85: get_weight = 79; 86: get_weight = -32; 87: get_weight = 40; 
                88: get_weight = -57; 89: get_weight = 72; 90: get_weight = -50; 91: get_weight = -95; 92: get_weight = -28; 93: get_weight = 62; 94: get_weight = 77; 95: get_weight = 20; 
                // --- Digit 2 ---
                96: get_weight = -33; 97: get_weight = -34; 98: get_weight = -16; 99: get_weight = 18; 100: get_weight = -41; 101: get_weight = -117; 102: get_weight = -38; 103: get_weight = 97; 104: get_weight = 7; 105: get_weight = 11; 
                106: get_weight = 4; 107: get_weight = -52; 108: get_weight = 49; 109: get_weight = 68; 110: get_weight = -51; 111: get_weight = -62; 112: get_weight = 20; 113: get_weight = 21; 114: get_weight = 27; 115: get_weight = -37; 
                116: get_weight = 28; 117: get_weight = -6; 118: get_weight = 60; 119: get_weight = -107; 120: get_weight = 20; 121: get_weight = -8; 122: get_weight = -18; 123: get_weight = 59; 124: get_weight = -7; 125: get_weight = 124; 
                126: get_weight = 2; 127: get_weight = -123; 128: get_weight = -8; 129: get_weight = -20; 130: get_weight = 45; 131: get_weight = -88; 132: get_weight = -25; 133: get_weight = 4; 134: get_weight = -64; 135: get_weight = -14; 
                136: get_weight = 50; 137: get_weight = -127; 138: get_weight = 4; 139: get_weight = 12; 140: get_weight = 1; 141: get_weight = 44; 142: get_weight = 36; 143: get_weight = 23; 
                // --- Digit 3 ---
                144: get_weight = -18; 145: get_weight = -3; 146: get_weight = 10; 147: get_weight = -78; 148: get_weight = -35; 149: get_weight = -88; 150: get_weight = -16; 151: get_weight = 72; 152: get_weight = 127; 153: get_weight = -56; 
                154: get_weight = -6; 155: get_weight = -53; 156: get_weight = 3; 157: get_weight = -30; 158: get_weight = -50; 159: get_weight = -105; 160: get_weight = -59; 161: get_weight = -30; 162: get_weight = -34; 163: get_weight = -99; 
                164: get_weight = 30; 165: get_weight = 92; 166: get_weight = 14; 167: get_weight = 16; 168: get_weight = 57; 169: get_weight = -50; 170: get_weight = 12; 171: get_weight = 50; 172: get_weight = 15; 173: get_weight = -25; 
                174: get_weight = 0; 175: get_weight = 12; 176: get_weight = -27; 177: get_weight = -2; 178: get_weight = -21; 179: get_weight = -9; 180: get_weight = 25; 181: get_weight = 17; 182: get_weight = 37; 183: get_weight = 96; 
                184: get_weight = 38; 185: get_weight = -124; 186: get_weight = -37; 187: get_weight = 25; 188: get_weight = -5; 189: get_weight = 6; 190: get_weight = 17; 191: get_weight = 30; 
                // --- Digit 4 ---
                192: get_weight = 11; 193: get_weight = 62; 194: get_weight = 17; 195: get_weight = -90; 196: get_weight = -59; 197: get_weight = -23; 198: get_weight = 32; 199: get_weight = -29; 200: get_weight = 83; 201: get_weight = -55; 
                202: get_weight = -70; 203: get_weight = -127; 204: get_weight = 73; 205: get_weight = -15; 206: get_weight = 5; 207: get_weight = -4; 208: get_weight = -62; 209: get_weight = 69; 210: get_weight = -22; 211: get_weight = 43; 
                212: get_weight = -79; 213: get_weight = 33; 214: get_weight = -4; 215: get_weight = 89; 216: get_weight = -10; 217: get_weight = -62; 218: get_weight = 66; 219: get_weight = 18; 220: get_weight = -21; 221: get_weight = 49; 
                222: get_weight = 31; 223: get_weight = -77; 224: get_weight = 39; 225: get_weight = -93; 226: get_weight = -64; 227: get_weight = 39; 228: get_weight = -25; 229: get_weight = 71; 230: get_weight = 127; 231: get_weight = -55; 
                232: get_weight = 48; 233: get_weight = -23; 234: get_weight = 22; 235: get_weight = -127; 236: get_weight = -30; 237: get_weight = 71; 238: get_weight = 24; 239: get_weight = 44; 
                // --- Digit 5 ---
                240: get_weight = 41; 241: get_weight = -118; 242: get_weight = -7; 243: get_weight = -80; 244: get_weight = -11; 245: get_weight = 0; 246: get_weight = 31; 247: get_weight = -34; 248: get_weight = 12; 249: get_weight = 5; 
                250: get_weight = 58; 251: get_weight = 78; 252: get_weight = 8; 253: get_weight = -6; 254: get_weight = -9; 255: get_weight = -11; 256: get_weight = 12; 257: get_weight = 14; 258: get_weight = 53; 259: get_weight = -3; 
                260: get_weight = -75; 261: get_weight = 3; 262: get_weight = -31; 263: get_weight = 14; 264: get_weight = 6; 265: get_weight = 56; 266: get_weight = 23; 267: get_weight = 29; 268: get_weight = -45; 269: get_weight = 41; 
                270: get_weight = 39; 271: get_weight = 12; 272: get_weight = -64; 273: get_weight = -24; 274: get_weight = -55; 275: get_weight = -19; 276: get_weight = 53; 277: get_weight = 13; 278: get_weight = -120; 279: get_weight = 15; 
                280: get_weight = 37; 281: get_weight = -42; 282: get_weight = 20; 283: get_weight = -83; 284: get_weight = 12; 285: get_weight = -58; 286: get_weight = 36; 287: get_weight = -85; 
                // --- Digit 6 ---
                288: get_weight = 88; 289: get_weight = -44; 290: get_weight = -23; 291: get_weight = 46; 292: get_weight = 30; 293: get_weight = -63; 294: get_weight = 9; 295: get_weight = -37; 296: get_weight = 25; 297: get_weight = 46; 
                298: get_weight = -27; 299: get_weight = -33; 300: get_weight = -44; 301: get_weight = -23; 302: get_weight = 13; 303: get_weight = 34; 304: get_weight = -10; 305: get_weight = 6; 306: get_weight = 3; 307: get_weight = -33; 
                308: get_weight = 96; 309: get_weight = -67; 310: get_weight = -54; 311: get_weight = 32; 312: get_weight = -36; 313: get_weight = 27; 314: get_weight = 41; 315: get_weight = 68; 316: get_weight = 2; 317: get_weight = -6; 
                318: get_weight = 39; 319: get_weight = 0; 320: get_weight = 60; 321: get_weight = 32; 322: get_weight = 30; 323: get_weight = -9; 324: get_weight = 27; 325: get_weight = 11; 326: get_weight = 33; 327: get_weight = 16; 
                328: get_weight = 18; 329: get_weight = 59; 330: get_weight = 33; 331: get_weight = -16; 332: get_weight = -25; 333: get_weight = 2; 334: get_weight = -5; 335: get_weight = -25; 
                // --- Digit 7 ---
                336: get_weight = 11; 337: get_weight = 9; 338: get_weight = -22; 339: get_weight = 44; 340: get_weight = -19; 341: get_weight = 49; 342: get_weight = -45; 343: get_weight = 27; 344: get_weight = 10; 345: get_weight = 26; 
                346: get_weight = 6; 347: get_weight = -1; 348: get_weight = -52; 349: get_weight = -13; 350: get_weight = -8; 351: get_weight = 49; 352: get_weight = -90; 353: get_weight = -92; 354: get_weight = 75; 355: get_weight = -15; 
                356: get_weight = -8; 357: get_weight = 109; 358: get_weight = -48; 359: get_weight = -16; 360: get_weight = 35; 361: get_weight = -46; 362: get_weight = 89; 363: get_weight = -21; 364: get_weight = 69; 365: get_weight = -57; 
                366: get_weight = 19; 367: get_weight = 66; 368: get_weight = -8; 369: get_weight = -1; 370: get_weight = 47; 371: get_weight = 93; 372: get_weight = 20; 373: get_weight = -8; 374: get_weight = -7; 375: get_weight = -17; 
                376: get_weight = 3; 377: get_weight = 42; 378: get_weight = -87; 379: get_weight = -44; 380: get_weight = -94; 381: get_weight = 21; 382: get_weight = -4; 383: get_weight = 92; 
                // --- Digit 8 ---
                384: get_weight = -37; 385: get_weight = -12; 386: get_weight = 0; 387: get_weight = -23; 388: get_weight = -4; 389: get_weight = 14; 390: get_weight = -47; 391: get_weight = 54; 392: get_weight = 21; 393: get_weight = -25; 
                394: get_weight = 78; 395: get_weight = -81; 396: get_weight = 5; 397: get_weight = 4; 398: get_weight = 11; 399: get_weight = 37; 400: get_weight = -21; 401: get_weight = 25; 402: get_weight = 73; 403: get_weight = -82; 
                404: get_weight = 12; 405: get_weight = -54; 406: get_weight = -38; 407: get_weight = -6; 408: get_weight = -7; 409: get_weight = -79; 410: get_weight = -103; 411: get_weight = -9; 412: get_weight = 56; 413: get_weight = -39; 
                414: get_weight = -102; 415: get_weight = -54; 416: get_weight = 13; 417: get_weight = 90; 418: get_weight = 44; 419: get_weight = -55; 420: get_weight = -18; 421: get_weight = -12; 422: get_weight = 6; 423: get_weight = -43; 
                424: get_weight = 46; 425: get_weight = -37; 426: get_weight = -18; 427: get_weight = 72; 428: get_weight = -73; 429: get_weight = 7; 
                // --- Digit 9 ---
                430: get_weight = 58; 431: get_weight = 58; 432: get_weight = -27; 433: get_weight = -106; 434: get_weight = 14; 435: get_weight = -126; 436: get_weight = 16; 437: get_weight = 71; 438: get_weight = -90; 439: get_weight = -16; 
                440: get_weight = -25; 441: get_weight = 77; 442: get_weight = 28; 443: get_weight = 34; 444: get_weight = 26; 445: get_weight = 34; 446: get_weight = -27; 447: get_weight = -10; 448: get_weight = 2; 449: get_weight = -16; 
                450: get_weight = -25; 451: get_weight = 25; 452: get_weight = -20; 453: get_weight = 12; 454: get_weight = -53; 455: get_weight = 44; 456: get_weight = -22; 457: get_weight = -33; 458: get_weight = -63; 459: get_weight = 9; 
                460: get_weight = -2; 461: get_weight = -61; 462: get_weight = -2; 463: get_weight = 106; 464: get_weight = -61; 465: get_weight = 87; 466: get_weight = 18; 467: get_weight = -87; 468: get_weight = 13; 469: get_weight = -86; 
                470: get_weight = 35; 471: get_weight = 96; 472: get_weight = 24; 473: get_weight = 2; 474: get_weight = -63; 475: get_weight = 11; 476: get_weight = -5; 477: get_weight = -47; 478: get_weight = 11; 479: get_weight = -13; 
                default: get_weight = 0;
            endcase
        end
    endfunction

    function signed [ACC_W-1:0] get_bias(input integer out_idx);
        begin
            get_bias = 0; // Bias는 0으로 가정
        end
    endfunction

    // --------------------------------------------------------
    // 3. 순차 계산 & ArgMax (Pipeline 적용)
    // --------------------------------------------------------
    reg [3:0] current_class; // 0~9
    reg [5:0] mac_idx;       // 0~47
    reg signed [ACC_W-1:0] accumulator;
    
    // Pipeline Registers
    reg signed [DATA_W-1:0] p_weight;
    reg signed [DATA_W-1:0] p_input;
    reg p_valid; // 계산 Enable 신호
    
    reg signed [ACC_W-1:0] max_score;
    reg [3:0] winner_class;

    reg [1:0] state;
    localparam S_IDLE = 0, S_CALC = 1, S_DONE = 2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            valid_out <= 0;
            predicted_class <= 0;
            current_class <= 0;
            mac_idx <= 0;
            accumulator <= 0;
            max_score <= -2147483647;
            p_valid <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    valid_out <= 0;
                    if (buffering_done) begin
                        state <= S_CALC;
                        current_class <= 0;
                        mac_idx <= 0;
                        accumulator <= get_bias(0); 
                        max_score <= -2147483647;
                        p_valid <= 0;
                    end
                end

                S_CALC: begin
                    // [Stage 1: Fetch] -------------------------
                    if (mac_idx < IN_NODES) begin
                        p_weight <= get_weight(current_class, mac_idx);
                        p_input  <= input_buffer[mac_idx];
                        p_valid  <= 1;
                        mac_idx  <= mac_idx + 1;
                    end else begin
                        p_valid <= 0; // 더 이상 가져올 데이터 없음
                        
                        // [Wait Flush] 파이프라인 마지막 계산이 끝날 때까지 대기
                        if (p_valid == 0) begin
                            // 한 클래스 계산 완료 -> 최대값 갱신
                            if (accumulator > max_score) begin
                                max_score <= accumulator;
                                winner_class <= current_class;
                            end

                            // 다음 클래스로 이동
                            if (current_class == OUT_NODES - 1) begin
                                state <= S_DONE;
                            end else begin
                                current_class <= current_class + 1;
                                mac_idx <= 0;
                                accumulator <= get_bias(current_class + 1);
                            end
                        end
                    end
                    
                    // [Stage 2: MAC] ---------------------------
                    if (p_valid) begin
                        // 1클럭 전에 가져온 데이터로 계산
                        accumulator <= accumulator + (p_input * p_weight);
                    end
                end

                S_DONE: begin
                    valid_out <= 1;
                    predicted_class <= winner_class;
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule