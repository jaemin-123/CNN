/*******************************************************************
@file convnet_params.h
*  @brief variable prototypes for model parameters and amax values
*
*
*  @author Benjamin Fuhrer
*
*******************************************************************/
#ifndef CONVNET_PARAMS
#define CONVNET_PARAMS

#define INPUT_DIM 784
#define H1 28
#define W1 28
#define H1_conv 24
#define W1_conv 24
#define H1_pool 12
#define W1_pool 12
#define H2_conv 8
#define W2_conv 8
#define H2_pool 4
#define W2_pool 4
#define C0 1
#define C1 3
#define C2 3
#define OUTPUT_DIM 10

#include <stdint.h>


// quantization/dequantization constants
extern const int layer_1_s_x;
extern const int layer_1_s_x_inv;
extern const int layer_1_s_w_inv[3];
extern const int layer_2_s_x;
extern const int layer_2_s_x_inv;
extern const int layer_2_s_w_inv[3];
extern const int layer_3_s_x;
extern const int layer_3_s_x_inv;
extern const int layer_3_s_w_inv[10];
// Layer quantized parameters
extern const int8_t layer_1_weight[75];
extern const int layer_1_bias[9];
extern const int8_t layer_2_weight[225];
extern const int layer_2_bias[9];
extern const int8_t layer_3_weight[480];
extern const int layer_3_bias[100];

#endif // end of CONVNET_PARAMS
