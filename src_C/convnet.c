#include "convnet.h"
#include "nn.h"
#include "nn_math.h"
#include <stdio.h> // printf 사용

void run_convnet(const int *x, unsigned int *class_indices)
{
	setbuf(stdout, NULL); // [추가] 출력 버퍼 끄기 (즉시 출력)
    // [수정] 반복문 변수 'i'를 함수 맨 위에 선언 (컴파일 에러 해결)
    int i;

    // ---------------------------------------------------------
    // Layer 1 실행
    // ---------------------------------------------------------
    int out_conv1[BATCH_SIZE*C1*H1_conv*W1_conv];

    conv2d_layer(x, layer_1_weight, out_conv1, layer_1_s_x, layer_1_s_w_inv, layer_1_s_x_inv,
                 BATCH_SIZE, C0, C1, H1, W1, H1_conv, W1_conv,
                 5, 5,  1, 1);

    int out_pool1[BATCH_SIZE*C1*H1_pool*W1_pool];
    pooling2d(out_conv1, out_pool1, BATCH_SIZE, C1, H1_conv, W1_conv, H1_pool, W1_pool, 2, 2,  2, 2);
    
    // [★디버깅] Layer 1 결과 출력
    printf("\n=== [C DEBUG] Layer 1 Output (After Pooling) ===\n");
    printf("CH 0: ");
    for(i=0; i<10; i++) printf("%d ", out_pool1[i]); // int i 선언 제거
    printf("\nCH 1: ");
    for(i=0; i<10; i++) printf("%d ", out_pool1[144 + i]); 
    printf("\nCH 2: ");
    for(i=0; i<10; i++) printf("%d ", out_pool1[288 + i]); 
    printf("\n==============================================\n");

    // ---------------------------------------------------------
    // Layer 2 실행
    // ---------------------------------------------------------
    int out_conv2[BATCH_SIZE*C2*H2_conv*W2_conv];
    conv2d_layer(out_pool1, layer_2_weight, out_conv2, layer_2_s_x, layer_2_s_w_inv, layer_2_s_x_inv,
                 BATCH_SIZE, C1, C2, H1_pool, W1_pool, H2_conv, W2_conv,
                 5, 5, 1, 1);

    int out_pool2[BATCH_SIZE*C2*H2_pool*W2_pool];
    pooling2d(out_conv2, out_pool2, BATCH_SIZE, C2, H2_conv, W2_conv, H2_pool, W2_pool, 2, 2, 2, 2);

    // [★디버깅] Layer 2 결과 출력
    printf("\n=== [C DEBUG] Layer 2 Output (After Pooling) ===\n");
    printf("CH 0: ");
    for(i=0; i<10; i++) printf("%d ", out_pool2[i]); 
    printf("\nCH 1: ");
    for(i=0; i<10; i++) printf("%d ", out_pool2[16 + i]); 
    printf("\nCH 2: ");
    for(i=0; i<10; i++) printf("%d ", out_pool2[32 + i]); 
    printf("\n==============================================\n");

    // ---------------------------------------------------------
    // FC Layer 실행
    // ---------------------------------------------------------
    int out_fc[BATCH_SIZE*OUTPUT_DIM];
    linear_layer(out_pool2, layer_3_weight, out_fc, layer_3_s_x, layer_3_s_w_inv, layer_3_s_x_inv,
                 BATCH_SIZE, C2*H2_pool*W2_pool, OUTPUT_DIM, 0);

    // [★디버깅] 최종 FC 점수 출력
    printf("\n=== [C DEBUG] Final FC Scores ===\n");
    for(i=0; i<10; i++) printf("Class %d: %d\n", i, out_fc[i]);
    printf("=================================\n");

    argmax_over_cols(out_fc, class_indices, BATCH_SIZE, OUTPUT_DIM);
}
