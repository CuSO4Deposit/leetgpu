#include <cuda_runtime.h>
#define TILE_WIDTH 16

__global__ void matrix_multiplication_kernel(const float* A, const float* B, float* C, int M, int N,
                                             int K) {
    __shared__ float ds_A[TILE_WIDTH][TILE_WIDTH];
    __shared__ float ds_B[TILE_WIDTH][TILE_WIDTH];
    int bx = blockIdx.x; int by = blockIdx.y;
    int tx = threadIdx.x; int ty = threadIdx.y;

    int row = by * TILE_WIDTH + ty;
    int col = bx * TILE_WIDTH + tx;
    float value = 0;

    for (int m = 0; m < (N + TILE_WIDTH - 1) / TILE_WIDTH; m++) {
        ds_A[ty][tx] = (row < M && m * TILE_WIDTH + tx < N) ? A[row * N + (m * TILE_WIDTH + tx)] : 0;  // A[row][m * TILE_WIDTH + tx]
        ds_B[ty][tx] = (col < K && m * TILE_WIDTH + ty < N) ? B[(m * TILE_WIDTH + ty) * K + col] : 0;  // B[m * TILE_WIDTH + ty][col]
        __syncthreads();

        for (int k = 0; k < TILE_WIDTH; k++) {
            value += ds_A[ty][k] * ds_B[k][tx];
        }
        __syncthreads();
    }

    if (row < M && col < K) {
        C[row * K + col] = value;
    }
}

// A, B, C are device pointers (i.e. pointers to memory on the GPU)
extern "C" void solve(const float* A, const float* B, float* C, int M, int N, int K) {
    dim3 threadsPerBlock(TILE_WIDTH, TILE_WIDTH);
    dim3 blocksPerGrid((K + threadsPerBlock.x - 1) / threadsPerBlock.x,
                       (M + threadsPerBlock.y - 1) / threadsPerBlock.y);

    matrix_multiplication_kernel<<<blocksPerGrid, threadsPerBlock>>>(A, B, C, M, N, K);
    cudaDeviceSynchronize();
}
