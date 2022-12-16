#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <time.h>
#include <cuda.h>
#include <cuda_runtime_api.h>
#include <assert.h>

#define MEGA 1024 * 1024
#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, char* file, int line, bool abort=true){
    if (code != cudaSuccess)
    {
        fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort)
            exit(code);
    }
}
 
__global__ void multiplyMatrix(int* matrix, int* res_matrix, int size){
    int row = blockDim.x * blockIdx.x + threadIdx.x;
    int column = blockDim.y * blockIdx.y + threadIdx.y;
    if (row < size && column < size){
        int sum = 0;
        for (int rank = 0; rank < size; rank++)
            sum += matrix[row * size + rank] * matrix[rank * size + column];
        res_matrix[row * size + column] = sum;
    }
}

int main(int argc, char *argv[]){
    float start_time = (float)clock();
    int size_of_data = 0;
    FILE* fp = fopen("input", "rb");
    int count_of_matrices;
    fread(&count_of_matrices, sizeof(int), 1, fp);
    int** matrices = (int**) malloc(count_of_matrices * sizeof(int*));
    int* ranks_of_matrices = (int*) malloc(count_of_matrices * sizeof(int));
    for (int index_of_matrix = 0; index_of_matrix < count_of_matrices; index_of_matrix++){
        int rang;
        fread(&rang, sizeof(int), 1, fp);
        ranks_of_matrices[index_of_matrix] = rang;
        matrices[index_of_matrix] = (int*) malloc(rang * rang * sizeof(int));
        for (int row = 0; row < rang; row++)
            for (int column = 0; column < rang; column++)
                fread(&matrices[index_of_matrix][row * rang + column], sizeof(int), 1, fp);
        size_of_data += rang * rang * sizeof(int);
    }
    fclose(fp);
    for (int index_of_matrix = 0; index_of_matrix < count_of_matrices; index_of_matrix++){
        int* buffer_matrix = (int*) malloc(ranks_of_matrices[index_of_matrix] * ranks_of_matrices[index_of_matrix] * sizeof(int));
        int* cuda_matrix;
        gpuErrchk( cudaMalloc((void**)&cuda_matrix, ranks_of_matrices[index_of_matrix] * ranks_of_matrices[index_of_matrix] * sizeof(int)) );
        int* cuda_res_matrix;
        gpuErrchk( cudaMalloc((void**)&cuda_res_matrix, ranks_of_matrices[index_of_matrix] * ranks_of_matrices[index_of_matrix] * sizeof(int)) );
        gpuErrchk( cudaMemcpy(cuda_matrix, matrices[index_of_matrix], ranks_of_matrices[index_of_matrix] * ranks_of_matrices[index_of_matrix] * sizeof(int), cudaMemcpyHostToDevice    ) );
        dim3 threadsPerBlock(ranks_of_matrices[index_of_matrix], ranks_of_matrices[index_of_matrix]);
        dim3 numBlocks(ranks_of_matrices[index_of_matrix] / threadsPerBlock.x, ranks_of_matrices[index_of_matrix] / threadsPerBlock.y);
        multiplyMatrix<<<numBlocks, threadsPerBlock>>>(cuda_matrix, cuda_res_matrix, ranks_of_matrices[index_of_matrix]);
        gpuErrchk( cudaMemcpy(buffer_matrix, cuda_res_matrix, ranks_of_matrices[index_of_matrix] * ranks_of_matrices[index_of_matrix] * sizeof(int), cudaMemcpyDeviceToHost));
        for (int row = 0; row < ranks_of_matrices[index_of_matrix]; row++)
            for (int column = 0; column < ranks_of_matrices[index_of_matrix]; column++)
                matrices[index_of_matrix][row * ranks_of_matrices[index_of_matrix] + column] = buffer_matrix[row * ranks_of_matrices[index_of_matrix] + column];
        free(buffer_matrix);
        gpuErrchk( cudaFree(cuda_matrix) );
        gpuErrchk( cudaFree(cuda_res_matrix) );
    }
    fp = fopen("output.txt", "w");
    fprintf(fp, "%d\n", count_of_matrices);
    for (int index_of_matrix = 0; index_of_matrix < count_of_matrices; index_of_matrix++){
        fprintf(fp, "%d\n", ranks_of_matrices[index_of_matrix]);
        for (int row = 0; row < ranks_of_matrices[index_of_matrix]; row++){
            for (int column = 0; column < ranks_of_matrices[index_of_matrix]; column++)
                fprintf(fp, "%d ", matrices[index_of_matrix][row * ranks_of_matrices[index_of_matrix] + column]);
            fputs("\n", fp);
        }
    }
    for (int index_of_matrix = 0; index_of_matrix < count_of_matrices; index_of_matrix++){
        free(matrices[index_of_matrix]);
    }
    free(matrices);
    free(ranks_of_matrices);
    float end_time = ((float)clock()) - start_time;
    fprintf(fp, "Count time: %f s\n", (float)size_of_data / (MEGA));
    fprintf(fp, "Size of data: %f Mb\n", end_time / 1000000);
    printf("Success!\n");
    return 0;
}
