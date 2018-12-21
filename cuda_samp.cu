#include<iostream>
#include<time.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include"device_functions.h"
using namespace std;
double *generator(int Num);
#define N 8000;
__global__ void convByGPU(double *A, double *out, double *window) {
	__shared__ double temp[16 * 16];
	int Num = N;
	int i;
	const int xIndex = blockDim.x*blockIdx.x + threadIdx.x;
	const int yIndex = blockDim.y*blockIdx.y + threadIdx.y;
	if (xIndex < Num&&yIndex < Num) {
		double convW[9] = { A[Num*xIndex + yIndex],A[Num*xIndex + yIndex + 1],A[Num*xIndex + yIndex + 2],A[Num*(xIndex + 1) + yIndex],A[Num*(xIndex + 1) + yIndex + 1],A[Num*(xIndex + 1) + yIndex + 2],
						A[Num*(xIndex + 2) + yIndex],A[Num*(xIndex + 2) + yIndex + 1],A[Num*(xIndex + 2) + yIndex + 2] };
		temp[threadIdx.y + threadIdx.x * 16] = 0.0;
		for (i = 0; i < 9; i++) {
			temp[threadIdx.x * 16 + threadIdx.y] += convW[i] * window[i];
		}
		__syncthreads();
		i = 2;
		const int temp_index = threadIdx.x * 16 + threadIdx.y;
		while (i <= 16 * 16) {
			if (temp_index%i == 0) {
				if (temp[temp_index] < temp[temp_index + i / 2])
					temp[temp_index] = temp[temp_index + i / 2];
			}
			__syncthreads();
			i = i * 2;
		}
		out[blockIdx.x*Num / 16 + blockIdx.y] = temp[0];
	}


}
class convfunc {
private:
	double window1[9] = { 1.0 / 9.0,1.0 / 9.0,1.0 / 9.0,1.0 / 9.0,1.0 / 9.0,1.0 / 9.0,1.0 / 9.0,1.0 / 9.0,1.0 / 9.0 };
	double window2[9] = { 1.0 / 12.0,1.0 / 6.0,1.0 / 12.0,1.0 / 6.0,1.0 / 3.0,1.0 / 6.0,1 / 12.0,1.0 / 6.0,1.0 / 12.0 };
	double window3[9] = { 0,1,0,-1,0,-1,-1,1,0 };
public:
	void convCPU(double *A, double *out) {
		int i, j, m, n;
		double tmp;
		int Num = N;
		double *temp = new double[Num*Num];
		clock_t time[2] = {};
		time[0] = clock();
		for (i = 0; i < Num; i++) {
			for (j = 0; j < Num; j++) {
				temp[Num*i + j] = 0;
				double convW[9] = { A[Num*i + j],A[Num*i + j + 1],A[Num*i + j + 2],A[Num*(i + 1) + j],A[Num*(i + 1) + j + 1],A[Num*(i + 1) + j + 2],
					A[Num*(i + 2) + j],A[Num*(i + 2) + j + 1],A[Num*(i + 2) + j + 2] };
				for (m = 0; m < 9; m++) {
					temp[Num*i + j] += convW[m] * window2[m];
				}

			}

		}
		for (i = 0; i < Num / 16; i++) {
			for (j = 0; j < Num / 16; j++) {
				tmp = -99;
				for (m = 0; m < 16; m++) {
					for (n = 0; n < 16; n++) {
						if (temp[16 * i + m + (16 * j + n)*Num] > tmp)
							tmp = temp[16 * i + m + (16 * j + n)*Num];

					}
				}
				out[i + j * Num / 16] = tmp;

			}
		}
		time[1] = clock();
		cout << "cpu time :" << double(time[1] - time[0]) / CLOCKS_PER_SEC << endl;
	}
	void convGPU(double *A, double *out) {
		int Num = N;
		double *cuda_A;
		clock_t time[2] = {};
		double *cuda_out, *cuda_window;
		time[0] = clock();
		dim3 dimGrid(512, 512);
		dim3 dimBlock(16, 16);
		cudaMalloc((void**)&cuda_A, sizeof(double)*(Num + 2)*(Num + 2));
		cudaMalloc((void**)&cuda_out, sizeof(double)*Num / 16 * Num / 16);
		cudaMalloc((void**)&cuda_window, sizeof(double) * 9);
		cudaMemcpy(cuda_A, A, sizeof(double)*(Num + 2)*(Num + 2), cudaMemcpyHostToDevice);
		cudaMemcpy(cuda_window, window2, sizeof(double) * 9, cudaMemcpyHostToDevice);
		convByGPU << <dimGrid, dimBlock >> > (cuda_A, cuda_out, cuda_window);
		cudaMemcpy(out, cuda_out, sizeof(double)*Num / 16 * Num / 16, cudaMemcpyDeviceToHost);
		time[1] = clock();
		cudaFree(cuda_A);
		cudaFree(cuda_out);
		cudaFree(cuda_window);
		cout << "gpu time :" << double(time[1] - time[0]) / CLOCKS_PER_SEC << endl;

	}

};

double *generator(int Num) {
	int m, n;
	Num += 2;
	double *matrixA = new double[Num*Num];
	for (m = 0; m < Num; m++) {
		for (n = 0; n < Num; n++) {
			matrixA[Num * m + n] = double(n + m) / Num * 100 + (double)(rand() % 94251473) / 194267847;
		}

	}
	return matrixA;

}
int main() {
	cudaDeviceProp deviceProp;
	int deviceCount;
	cudaError_t cudaError;
	cudaError = cudaGetDeviceCount(&deviceCount);
	for (int i = 0; i < deviceCount; i++) {
		cudaError = cudaGetDeviceProperties(&deviceProp, i);
		cout << "设备 " << i + 1 << " 的主要属性： " << endl;
		cout << "设备显卡型号： " << deviceProp.name << endl;
		cout << "设备全局内存总量（以MB为单位）： " << deviceProp.totalGlobalMem / 1024 / 1024 << endl;
		cout << "线程块（Block）中可用的最大共享内存（以KB为单位）： " << deviceProp.sharedMemPerBlock / 1024 << endl;
		cout << "线程块（Block）种可用的32位寄存器数量： " << deviceProp.regsPerBlock << endl;
		cout << "线程块（Block）可包含的最大线程数量： " << deviceProp.maxThreadsPerBlock << endl;
		cout << "设备的计算功能集（Compute Capability）的版本号： " << deviceProp.major << "." << deviceProp.minor << endl;
		cout << "设备上多处理器的数量： " << 192 * deviceProp.multiProcessorCount << endl;
		cout << "设备线程束大小： " << deviceProp.warpSize << endl;
		cout << "GPU时钟频率(以KHz为单位)： " << deviceProp.clockRate << endl;
	}


	int i, j;
	int Num = N;
	double *matrixA = generator(Num);
	double err_mean, err_sum = 0.0;
	convfunc op;
	double *outMatrixCPU = new double[Num / 16 * Num / 16];
	double *outMatrixGPU = new double[Num / 16 * Num / 16];
	op.convCPU(matrixA, outMatrixCPU);
	op.convGPU(matrixA, outMatrixGPU);

	for (i = 0, err_sum = 0; i < Num / 16; i++) {
		for (j = 0; j < Num / 16; j++) {
			if (outMatrixCPU[i*Num / 16 + j] != 0) {
				err_sum += fabs(outMatrixCPU[i*Num / 16 + j] - outMatrixGPU[i*Num / 16 + j]) / fabs(outMatrixCPU[i*Num / 16 + j]);
			}
			else { err_sum += fabs(outMatrixCPU[i*Num / 16 + j] - outMatrixGPU[i*Num / 16 + j]); }
		}
	}
	err_mean = err_sum / (Num*Num / 16 / 16);
	printf("计算平均误差:%g\n", err_mean);

}