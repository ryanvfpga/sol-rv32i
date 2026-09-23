#define TEST_RESULT_ADDR ((volatile int*) 0x00000FFC)
#define N 8

int arr[N] = {5, 1, 4, 2, 8, 0, 7, 3};

int main() {
    int expected_sum = 0;
    for (int i = 0; i < N; i++) expected_sum += arr[i];
    
    for (int i = 0; i < N - 1; i++) {
        for (int j = 0; j < N - 1 - i; j++) {
            if (arr[j] > arr[j + 1]) {
                int tmp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = tmp;
            }
        }
    }

    int pass = 1;
    int actual_sum = 0;
    for (int i = 0; i < N; i++) {
        actual_sum += arr[i];
        if (i < N - 1 && arr[i] > arr[i + 1]) pass = 0;
    }
    if (actual_sum != expected_sum) pass = 0;   

    *TEST_RESULT_ADDR = pass ? 1 : 2;
    while (1);
    return 0;
}