# HST_LAB4
Генeрация матриц с однозначными цифрами  

Загрузка сгенерированных данных в файл (input)  

Запись данных в буфер с файла и отправка на девайса  

Формирование времени выполнения и размера обработанных данных  

Приницип работы
---------------
cudaMalloc - выделение памяти в gpu  

cudaMemcpyAsync - копируем данные из программы в область gpu  

Вычислительная функция (kernel) 
```
global void multiplyMatrix(int matrix, int res_matrix, int size){ 
  int row = blockDim.x * blockIdx.x + threadIdx.x; int column = blockDim.y * blockIdx.y + threadIdx.y; 
  if (row < size && column < size){ 
    int sum = 0; 
    for (int rank = 0; rank < size; rank++) 
    sum += matrix[row * size + rank] * matrix[rank * size + column]; 
    res_matrix[row * size + column] = sum; 
  } 
}
```
![image](https://user-images.githubusercontent.com/90069453/208177110-d48f5b64-63f5-4177-b9a5-4f6a5ab06b5b.png)


| Метод                     | 10 мб | 20 мб | 30 мб | 50 мб  | 100 мб |
|---------------------------|-------|-------|-------|--------|--------|
| Последовательный алгоритм | 800   | 1400  | 1950  | 3680   | 6140   |
| OpenMP                    | 850   | 1590  | 2160  | 3240   | 6310   |
| MPI                       | 750   | 1502  | 1900  | 2820   | 6700   |
| CUDA                      | 28209 | 51390 | 75200 | 131679 | 246669 |
