#include "nn.h"
#include "nn_math.h"
#include <stdio.h>

// linear_layer 함수: FC Layer의 입력값을 확인하기 위해 디버깅 코드 추가됨
void linear_layer(const int *x, const int8_t *w, int *output, const int x_scale_factor,
                  const int *w_scale_factor_inv, const int x_scale_factor_inv,
                  const unsigned int  N, const unsigned int  K, const unsigned int  M,
                  const unsigned int  hidden_layer)
{
    // [수정] 변수 i 선언을 맨 위로 (컴파일 에러 해결)
    int i;
    int8_t x_q[N * K];

    // 1. 입력 양자화 (32bit -> 8bit)
    quantize(x, x_q, x_scale_factor, x_scale_factor_inv,  N*K);

    // [★디버깅] Verilog의 Layer 2 출력(l2_pool_out)과 비교할 진짜 값(8bit) 출력
    printf("\n=== [C DEBUG] FC Layer Input (Quantized 8-bit) ===\n");
    printf("CH 0 (First 10): ");
    for(i=0; i<10; i++) printf("%d ", x_q[i]); 
    printf("\nCH 1 (First 10): ");
    for(i=0; i<10; i++) printf("%d ", x_q[16 + i]); // 4x4=16 offset
    printf("\nCH 2 (First 10): ");
    for(i=0; i<10; i++) printf("%d ", x_q[32 + i]); 
    printf("\n==================================================\n");

    // 2. 행렬 곱셈
    mat_mult(x_q, w, output, N, K, M);

    // 3. 역양자화
    dequantize_per_row(output, w_scale_factor_inv, x_scale_factor_inv, N, M);

    // 4. 활성화 함수
    if (hidden_layer)
        relu(output, N*M);
}

// conv2d_layer 함수: 기존과 동일 (변수 선언 위치 수정됨)
void conv2d_layer(const int *x, const int8_t *w, int *output, const int x_scale_factor, const int *w_scale_factor_inv, const int x_scale_factor_inv,
                  const unsigned int N, const unsigned int C_in, const unsigned int C_out, const int H, const int W,
                  const int H_conv, const int W_conv, const int k_size_h, const int k_size_w,  const int stride_h, const int stride_w)
{
    // [수정] 변수 선언 맨 위로
    int i;
    int8_t x_q[N * C_in * H * W];
    
    // 1. Quantize Input
    quantize(x, x_q, x_scale_factor, x_scale_factor_inv, N * C_in * H * W);

    // 2. Convolution 실행 (여기서 output에 '순수 합계'가 담김)
    conv2d(x_q, w, output, N, C_in, C_out, H, W, H_conv, W_conv,
            k_size_h, k_size_w,  stride_h, stride_w);
            
    // [★핵심 디버깅] Multiplier 곱하기 '직전'의 순수 합계 값 출력
    if (C_in > 1) { // Layer 2인 경우
        printf("\n=== [C DEBUG] Layer 2 RAW SUM (Before Mult) ===\n");
        printf("CH 0 (Pixel 0~4): ");
        for(i=0; i<5; i++) printf("%d ", output[i]); 
        printf("\n===============================================\n");
    }
    
    // 3. Dequantize (여기서 Multiplier가 곱해짐 - 값이 변함)
    dequantize_per_channel(output, w_scale_factor_inv, x_scale_factor_inv, N, C_out, H_conv*W_conv);

    relu(output, N*C_out*H_conv*W_conv);
}
