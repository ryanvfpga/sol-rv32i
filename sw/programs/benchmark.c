#define TEST_RESULT_ADDR ((volatile int*) 0x00000FFC)

#define ARRAY_SIZE 16
#define MATRIX_DIM 4
#define CHECKSUM_STEPS 64

// Datasets for various workload passes
int global_array[ARRAY_SIZE] = {
    0x12345678, 0x0F0F0F0F, 0x55555555, 0xAAAAAAAA,
    0x7FFFFFFF, 0x80000000, 0x00000001, 0xFFFFFFFF,
    0x00FF00FF, 0xFF00FF00, 0x1F2E3D4C, 0x5B6A7988,
    0x00001234, 0x43210000, 0x10203040, 0x01020304
};

unsigned char byte_buffer[32];
short halfword_buffer[16];

int matrix_a[MATRIX_DIM][MATRIX_DIM];
int matrix_b[MATRIX_DIM][MATRIX_DIM];
int matrix_res[MATRIX_DIM][MATRIX_DIM];

// Software PRNG (LCG) to generate pseudo-random patterns using pure RV32I ops
unsigned int prng_next(unsigned int seed) {
    // seed = seed * 1103515245 + 12345 using soft shift-add steps
    unsigned int acc = 0;
    for (int i = 0; i < 16; i++) {
        if ((seed >> i) & 1) {
            acc += (1103515245 << i);
        }
    }
    return acc + 12345;
}

// Software CRC32 implementation (heavy bit-shifting and XOR work)
unsigned int compute_crc32(const unsigned char *data, int length) {
    unsigned int crc = 0xFFFFFFFF;
    for (int i = 0; i < length; i++) {
        crc ^= data[i];
        for (int j = 0; j < 8; j++) {
            if (crc & 1) {
                crc = (crc >> 1) ^ 0xEDB88320;
            } else {
                crc >>= 1;
            }
        }
    }
    return ~crc;
}

int main() {
    int pass = 1;

    // -------------------------------------------------------------------------
    // WORKLOAD 1: Byte & Half-Word Memory Accesses (sb, lb, lbu, sh, lh, lhu)
    // -------------------------------------------------------------------------
    for (int i = 0; i < 32; i++) {
        byte_buffer[i] = (unsigned char)((i * 13 + 7) & 0xFF);
    }

    for (int i = 0; i < 16; i++) {
        halfword_buffer[i] = (short)((byte_buffer[i * 2] << 8) | byte_buffer[i * 2 + 1]);
    }

    unsigned int byte_sum = 0;
    for (int i = 0; i < 32; i++) {
        byte_sum += byte_buffer[i];
    }
    if (byte_sum != 3600) pass = 0;

    // -------------------------------------------------------------------------
    // WORKLOAD 2: Matrix Initialization, Transposition & Multiplication
    // -------------------------------------------------------------------------
    for (int r = 0; r < MATRIX_DIM; r++) {
        for (int c = 0; c < MATRIX_DIM; c++) {
            matrix_a[r][c] = (r + 1) * 10 + (c + 1);
            matrix_b[r][c] = (c + 1) * 100 + (r + 1);
            matrix_res[r][c] = 0;
        }
    }

    // Dense Matrix Multiplication (Software loops)
    for (int i = 0; i < MATRIX_DIM; i++) {
        for (int j = 0; j < MATRIX_DIM; j++) {
            int sum = 0;
            for (int k = 0; k < MATRIX_DIM; k++) {
                // Software multiplication (a * b) via bit-shifts and additions
                int val_a = matrix_a[i][k];
                int val_b = matrix_b[k][j];
                int prod = 0;
                
                while (val_b > 0) {
                    if (val_b & 1) prod += val_a;
                    val_a <<= 1;
                    val_b >>= 1;
                }
                sum += prod;
            }
            matrix_res[i][j] = sum;
        }
    }

    // Verify dynamic element from result matrix
    if (matrix_res[2][3] != 52330) pass = 0;

    // -------------------------------------------------------------------------
    // WORKLOAD 3: Heavy Bitwise Permutations & Software CRC32
    // -------------------------------------------------------------------------
    unsigned int crc = compute_crc32(byte_buffer, 32);
    if (crc != 0x30AE2EE3) pass = 0;

    // -------------------------------------------------------------------------
    // WORKLOAD 4: Multi-Pass Array Manipulation & Sub-Searching
    // -------------------------------------------------------------------------
    unsigned int seed = 0xDEADBEEF;
    for (int i = 0; i < ARRAY_SIZE; i++) {
        seed = prng_next(seed);
        global_array[i] ^= seed;
    }

    // Linear search & min/max stress test
    int min_val = global_array[0];
    int max_val = global_array[0];
    int accumulator = 0;

    for (int pass_idx = 0; pass_idx < 4; pass_idx++) {
        for (int i = 0; i < ARRAY_SIZE; i++) {
            if (global_array[i] < min_val) min_val = global_array[i];
            if (global_array[i] > max_val) max_val = global_array[i];

            // Conditional bit flips
            if ((global_array[i] & 0x1) == 0) {
                global_array[i] = (global_array[i] >> 1) ^ 0x00FF00FF;
            } else {
                global_array[i] = (global_array[i] << 1) | 0x1;
            }

            accumulator += (global_array[i] ^ pass_idx);
        }
    }

    if (accumulator == 0) pass = 0; // Sanity check on computation

    // -------------------------------------------------------------------------
    // WRITE RESULT & TERMINATE
    // -------------------------------------------------------------------------
    *TEST_RESULT_ADDR = pass ? 1 : 2;

    while (1);
    return 0;
}