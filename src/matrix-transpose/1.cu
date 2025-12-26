#include <cuda_runtime.h>
#define TILE_WIDTH 16

__global__ void matrix_transpose_kernel(const float* input, float* output, int rows, int cols) {
    int bx = blockIdx.x; int by = blockIdx.y;
    int tx = threadIdx.x; int ty = threadIdx.y;

    int r = by * TILE_WIDTH + ty;
    int c = bx * TILE_WIDTH + tx;

    if (r < rows && c < cols) {
        output[c * rows + r] = input[r * cols + c];  // B[c][r] <- A[r][c]
    }
}

// input, output are device pointers (i.e. pointers to memory on the GPU)
extern "C" void solve(const float* input, float* output, int rows, int cols) {
    dim3 threadsPerBlock(TILE_WIDTH, TILE_WIDTH);
    dim3 blocksPerGrid((cols + threadsPerBlock.x - 1) / threadsPerBlock.x,
                       (rows + threadsPerBlock.y - 1) / threadsPerBlock.y);

    matrix_transpose_kernel<<<blocksPerGrid, threadsPerBlock>>>(input, output, rows, cols);
    cudaDeviceSynchronize();
}
