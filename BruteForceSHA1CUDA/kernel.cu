
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

#define __u32 unsigned int 
#define __u8 unsigned char

cudaError_t addWithCuda(__u32 SHA1Sum[], __u8 SHA1Data[], int *retVal);


#define	FETCH_32(p)							\
	(((__u32)*((const __u8 *)(p) + 3)) |			\
	(((__u32)*((const __u8 *)(p) + 2)) << 8) |		\
	(((__u32)*((const __u8 *)(p) + 1)) << 16) |		\
	(((__u32)*((const __u8 *)(p))) << 24))

/* Constants from FIPS 180-1 */
#define	K_00_19		0x5a827999UL
#define	K_20_39		0x6ed9eba1UL
#define	K_40_59		0x8f1bbcdcUL
#define	K_60_79		0xca62c1d6UL

/* F, G, H and I are basic SHA1 functions. */
#define	F(b, c, d)	((((c) ^ (d)) & (b)) ^ (d))
#define	G(b, c, d)	((b) ^ (c) ^ (d))
#define	H(b, c, d)	(((b) & (c)) | (((b) | (c)) & (d)))

/* ROTATE_LEFT rotates x left n bits. */
#define	ROTATE_LEFT(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

/* R, R1-R4 are macros used during each transformation round. */
#define R(f, k, v, w, x, y, z, i) {				\
	(v) = ROTATE_LEFT(w, 5) + f(x, y, z) + (v) + (i) + (k);	\
	(x) = ROTATE_LEFT(x, 30);				\
}

#define	R1(v, w, x, y, z, i)	R(F, K_00_19, v, w, x, y, z, i)
#define	R2(v, w, x, y, z, i)	R(G, K_20_39, v, w, x, y, z, i)
#define	R3(v, w, x, y, z, i)	R(H, K_40_59, v, w, x, y, z, i)
#define	R4(v, w, x, y, z, i)	R(G, K_60_79, v, w, x, y, z, i)

#define	WUPDATE(p, q, r, s) {		\
	(p) = ((q) ^ (r) ^ (s) ^ (p));	\
	(p) = ROTATE_LEFT(p, 1);	\
}

void SHA1Init(__u32 mass[]) {
	mass[0] = 0x67452301UL;
	mass[1] = 0xefcdab89UL;
	mass[2] = 0x98badcfeUL;
	mass[3] = 0x10325476UL;
	mass[4] = 0xc3d2e1f0UL;
}

void
sha_transformINIT(__u32 mass[], __u8 block[])
{
	__u32 a = mass[0];
	__u32 b = mass[1];
	__u32 c = mass[2];
	__u32 d = mass[3];
	__u32 e = mass[4];

	/* Register (instead of array) is a win in most cases */
	__u32 w0, w1, w2, w3, w4, w5, w6, w7;
	__u32 w8, w9, w10, w11, w12, w13, w14, w15;

	w15 = FETCH_32(block + 60);
	w14 = FETCH_32(block + 56);
	w13 = FETCH_32(block + 52);
	w12 = FETCH_32(block + 48);
	w11 = FETCH_32(block + 44);
	w10 = FETCH_32(block + 40);
	w9 = FETCH_32(block + 36);
	w8 = FETCH_32(block + 32);
	w7 = FETCH_32(block + 28);
	w6 = FETCH_32(block + 24);
	w5 = FETCH_32(block + 20);
	w4 = FETCH_32(block + 16);
	w3 = FETCH_32(block + 12);
	w2 = FETCH_32(block + 8);
	w1 = FETCH_32(block + 4);
	w0 = FETCH_32(block + 0);

	/* Round 1 */
	R1(e, a, b, c, d, w0);		/*  0 */
	R1(d, e, a, b, c, w1);		/*  1 */
	R1(c, d, e, a, b, w2);		/*  2 */
	R1(b, c, d, e, a, w3);		/*  3 */
	R1(a, b, c, d, e, w4);		/*  4 */
	R1(e, a, b, c, d, w5);		/*  5 */
	R1(d, e, a, b, c, w6);		/*  6 */
	R1(c, d, e, a, b, w7);		/*  7 */
	R1(b, c, d, e, a, w8);		/*  8 */
	R1(a, b, c, d, e, w9);		/*  9 */
	R1(e, a, b, c, d, w10);		/* 10 */
	R1(d, e, a, b, c, w11);		/* 11 */
	R1(c, d, e, a, b, w12);		/* 12 */
	R1(b, c, d, e, a, w13);		/* 13 */
	R1(a, b, c, d, e, w14);		/* 14 */
	R1(e, a, b, c, d, w15);		/* 15 */
	WUPDATE(w0, w13, w8, w2);	R1(d, e, a, b, c, w0);		/* 16 */
	WUPDATE(w1, w14, w9, w3);	R1(c, d, e, a, b, w1);		/* 17 */
	WUPDATE(w2, w15, w10, w4);	R1(b, c, d, e, a, w2);		/* 18 */
	WUPDATE(w3, w0, w11, w5);	R1(a, b, c, d, e, w3);		/* 19 */

	/* Round 2 */
	WUPDATE(w4, w1, w12, w6);	R2(e, a, b, c, d, w4);		/* 20 */
	WUPDATE(w5, w2, w13, w7);	R2(d, e, a, b, c, w5);		/* 21 */
	WUPDATE(w6, w3, w14, w8);	R2(c, d, e, a, b, w6);		/* 22 */
	WUPDATE(w7, w4, w15, w9);	R2(b, c, d, e, a, w7);		/* 23 */
	WUPDATE(w8, w5, w0, w10);	R2(a, b, c, d, e, w8);		/* 24 */
	WUPDATE(w9, w6, w1, w11);	R2(e, a, b, c, d, w9);		/* 25 */
	WUPDATE(w10, w7, w2, w12);	R2(d, e, a, b, c, w10);		/* 26 */
	WUPDATE(w11, w8, w3, w13);	R2(c, d, e, a, b, w11);		/* 27 */
	WUPDATE(w12, w9, w4, w14);	R2(b, c, d, e, a, w12);		/* 28 */
	WUPDATE(w13, w10, w5, w15);	R2(a, b, c, d, e, w13);		/* 29 */
	WUPDATE(w14, w11, w6, w0);	R2(e, a, b, c, d, w14);		/* 30 */
	WUPDATE(w15, w12, w7, w1);	R2(d, e, a, b, c, w15);		/* 31 */
	WUPDATE(w0, w13, w8, w2);	R2(c, d, e, a, b, w0);		/* 32 */
	WUPDATE(w1, w14, w9, w3);	R2(b, c, d, e, a, w1);		/* 33 */
	WUPDATE(w2, w15, w10, w4);	R2(a, b, c, d, e, w2);		/* 34 */
	WUPDATE(w3, w0, w11, w5);	R2(e, a, b, c, d, w3);		/* 35 */
	WUPDATE(w4, w1, w12, w6);	R2(d, e, a, b, c, w4);		/* 36 */
	WUPDATE(w5, w2, w13, w7);	R2(c, d, e, a, b, w5);		/* 37 */
	WUPDATE(w6, w3, w14, w8);	R2(b, c, d, e, a, w6);		/* 38 */
	WUPDATE(w7, w4, w15, w9);	R2(a, b, c, d, e, w7);		/* 39 */

	/* Round 3 */
	WUPDATE(w8, w5, w0, w10);	R3(e, a, b, c, d, w8);		/* 40 */
	WUPDATE(w9, w6, w1, w11);	R3(d, e, a, b, c, w9);		/* 41 */
	WUPDATE(w10, w7, w2, w12);	R3(c, d, e, a, b, w10);		/* 42 */
	WUPDATE(w11, w8, w3, w13);	R3(b, c, d, e, a, w11);		/* 43 */
	WUPDATE(w12, w9, w4, w14);	R3(a, b, c, d, e, w12);		/* 44 */
	WUPDATE(w13, w10, w5, w15);	R3(e, a, b, c, d, w13);		/* 45 */
	WUPDATE(w14, w11, w6, w0);	R3(d, e, a, b, c, w14);		/* 46 */
	WUPDATE(w15, w12, w7, w1);	R3(c, d, e, a, b, w15);		/* 47 */
	WUPDATE(w0, w13, w8, w2);	R3(b, c, d, e, a, w0);		/* 48 */
	WUPDATE(w1, w14, w9, w3);	R3(a, b, c, d, e, w1);		/* 49 */
	WUPDATE(w2, w15, w10, w4);	R3(e, a, b, c, d, w2);		/* 50 */
	WUPDATE(w3, w0, w11, w5);	R3(d, e, a, b, c, w3);		/* 51 */
	WUPDATE(w4, w1, w12, w6);	R3(c, d, e, a, b, w4);		/* 52 */
	WUPDATE(w5, w2, w13, w7);	R3(b, c, d, e, a, w5);		/* 53 */
	WUPDATE(w6, w3, w14, w8);	R3(a, b, c, d, e, w6);		/* 54 */
	WUPDATE(w7, w4, w15, w9);	R3(e, a, b, c, d, w7);		/* 55 */
	WUPDATE(w8, w5, w0, w10);	R3(d, e, a, b, c, w8);		/* 56 */
	WUPDATE(w9, w6, w1, w11);	R3(c, d, e, a, b, w9);		/* 57 */
	WUPDATE(w10, w7, w2, w12);	R3(b, c, d, e, a, w10);		/* 58 */
	WUPDATE(w11, w8, w3, w13);	R3(a, b, c, d, e, w11);		/* 59 */

	WUPDATE(w12, w9, w4, w14);	R4(e, a, b, c, d, w12);		/* 60 */
	WUPDATE(w13, w10, w5, w15);	R4(d, e, a, b, c, w13);		/* 61 */
	WUPDATE(w14, w11, w6, w0);	R4(c, d, e, a, b, w14);		/* 62 */
	WUPDATE(w15, w12, w7, w1);	R4(b, c, d, e, a, w15);		/* 63 */
	WUPDATE(w0, w13, w8, w2);	R4(a, b, c, d, e, w0);		/* 64 */
	WUPDATE(w1, w14, w9, w3);	R4(e, a, b, c, d, w1);		/* 65 */
	WUPDATE(w2, w15, w10, w4);	R4(d, e, a, b, c, w2);		/* 66 */
	WUPDATE(w3, w0, w11, w5);	R4(c, d, e, a, b, w3);		/* 67 */
	WUPDATE(w4, w1, w12, w6);	R4(b, c, d, e, a, w4);		/* 68 */
	WUPDATE(w5, w2, w13, w7);	R4(a, b, c, d, e, w5);		/* 69 */
	WUPDATE(w6, w3, w14, w8);	R4(e, a, b, c, d, w6);		/* 70 */
	WUPDATE(w7, w4, w15, w9);	R4(d, e, a, b, c, w7);		/* 71 */
	WUPDATE(w8, w5, w0, w10);	R4(c, d, e, a, b, w8);		/* 72 */
	WUPDATE(w9, w6, w1, w11);	R4(b, c, d, e, a, w9);		/* 73 */
	WUPDATE(w10, w7, w2, w12);	R4(a, b, c, d, e, w10);		/* 74 */
	WUPDATE(w11, w8, w3, w13);	R4(e, a, b, c, d, w11);		/* 75 */
	WUPDATE(w12, w9, w4, w14);	R4(d, e, a, b, c, w12);		/* 76 */
	WUPDATE(w13, w10, w5, w15);	R4(c, d, e, a, b, w13);		/* 77 */
	WUPDATE(w14, w11, w6, w0);	R4(b, c, d, e, a, w14);		/* 78 */
	WUPDATE(w15, w12, w7, w1);	R4(a, b, c, d, e, w15);		/* 79 */

	mass[0] += a;
	mass[1] += b;
	mass[2] += c;
	mass[3] += d;
	mass[4] += e;
}

__constant__ __u32 g_cSHA1baseCode[5];

__global__ void
sha_transform(int *ret_block, __u32 *in_block)
{
	__u32 *block = in_block + ((blockIdx.x << 5) + threadIdx.x) * 16;
	__u8 *pos_cur;

	__u32 a, b, c, d, e;
	/* Register (instead of array) is a win in most cases */
	__u32 w0, w1, w2, w3, w4, w5, w6, w7;
	__u32 w8, w9, w10, w11, w12, w13, w14, w15;
	__u32 wi[16];
	wi[0] = block[0];
	wi[1] = block[1];
	wi[2] = block[2];
	wi[3] = block[3];
	wi[4] = block[4];
	wi[5] = block[5];
	wi[6] = block[6];
	wi[7] = block[7];
	wi[8] = block[8];
	wi[9] = block[9];
	wi[10] = block[10];
	wi[11] = block[11];
	wi[12] = block[12];
	wi[13] = block[13];
	wi[14] = block[14];
	wi[15] = block[15];



	while (true) {
		pos_cur = (__u8*)wi;
		while (true) {
			if ((*pos_cur) == 126) {
				(*pos_cur) = 33;
				pos_cur++;
				continue;
			}
			(*pos_cur)++;

			a = g_cSHA1baseCode[0];
			b = g_cSHA1baseCode[1];
			c = g_cSHA1baseCode[2];
			d = g_cSHA1baseCode[3];
			e = g_cSHA1baseCode[4];

/*			w15 = FETCH_32((__u8 *)(block + 15));
			w14 = FETCH_32((__u8 *)(block + 14));
			w13 = FETCH_32((__u8 *)(block + 13));
			w12 = FETCH_32((__u8 *)(block + 12));
			w11 = FETCH_32((__u8 *)(block + 11));
			w10 = FETCH_32((__u8 *)(block + 10));
			w9 = FETCH_32((__u8 *)(block + 9));
			w8 = FETCH_32((__u8 *)(block + 8));
			w7 = FETCH_32((__u8 *)(block + 7));
			w6 = FETCH_32((__u8 *)(block + 6));
			w5 = FETCH_32((__u8 *)(block + 5));
			w4 = FETCH_32((__u8 *)(block + 4));
			w3 = FETCH_32((__u8 *)(block + 3));
			w2 = FETCH_32((__u8 *)(block + 2));
			w1 = FETCH_32((__u8 *)(block + 1));
			w0 = FETCH_32((__u8 *)(block + 0));
			*/
			w15 = wi[15];
			w14 = wi[14];
			w13 = wi[13];
			w12 = wi[12];
			w11 = wi[11];
			w10 = wi[10];
			w9 = wi[9];
			w8 = wi[8];
			w7 = wi[7];
			w6 = wi[6];
			w5 = wi[5];
			w4 = wi[4];
			w3 = wi[3];
			w2 = wi[2];
			w1 = wi[1];
			w0 = wi[0];

			/* Round 1 */
			R1(e, a, b, c, d, w0);		/*  0 */
			R1(d, e, a, b, c, w1);		/*  1 */
			R1(c, d, e, a, b, w2);		/*  2 */
			R1(b, c, d, e, a, w3);		/*  3 */
			R1(a, b, c, d, e, w4);		/*  4 */
			R1(e, a, b, c, d, w5);		/*  5 */
			R1(d, e, a, b, c, w6);		/*  6 */
			R1(c, d, e, a, b, w7);		/*  7 */
			R1(b, c, d, e, a, w8);		/*  8 */
			R1(a, b, c, d, e, w9);		/*  9 */
			R1(e, a, b, c, d, w10);		/* 10 */
			R1(d, e, a, b, c, w11);		/* 11 */
			R1(c, d, e, a, b, w12);		/* 12 */
			R1(b, c, d, e, a, w13);		/* 13 */
			R1(a, b, c, d, e, w14);		/* 14 */
			R1(e, a, b, c, d, w15);		/* 15 */
			WUPDATE(w0, w13, w8, w2);	R1(d, e, a, b, c, w0);		/* 16 */
			WUPDATE(w1, w14, w9, w3);	R1(c, d, e, a, b, w1);		/* 17 */
			WUPDATE(w2, w15, w10, w4);	R1(b, c, d, e, a, w2);		/* 18 */
			WUPDATE(w3, w0, w11, w5);	R1(a, b, c, d, e, w3);		/* 19 */

			/* Round 2 */
			WUPDATE(w4, w1, w12, w6);	R2(e, a, b, c, d, w4);		/* 20 */
			WUPDATE(w5, w2, w13, w7);	R2(d, e, a, b, c, w5);		/* 21 */
			WUPDATE(w6, w3, w14, w8);	R2(c, d, e, a, b, w6);		/* 22 */
			WUPDATE(w7, w4, w15, w9);	R2(b, c, d, e, a, w7);		/* 23 */
			WUPDATE(w8, w5, w0, w10);	R2(a, b, c, d, e, w8);		/* 24 */
			WUPDATE(w9, w6, w1, w11);	R2(e, a, b, c, d, w9);		/* 25 */
			WUPDATE(w10, w7, w2, w12);	R2(d, e, a, b, c, w10);		/* 26 */
			WUPDATE(w11, w8, w3, w13);	R2(c, d, e, a, b, w11);		/* 27 */
			WUPDATE(w12, w9, w4, w14);	R2(b, c, d, e, a, w12);		/* 28 */
			WUPDATE(w13, w10, w5, w15);	R2(a, b, c, d, e, w13);		/* 29 */
			WUPDATE(w14, w11, w6, w0);	R2(e, a, b, c, d, w14);		/* 30 */
			WUPDATE(w15, w12, w7, w1);	R2(d, e, a, b, c, w15);		/* 31 */
			WUPDATE(w0, w13, w8, w2);	R2(c, d, e, a, b, w0);		/* 32 */
			WUPDATE(w1, w14, w9, w3);	R2(b, c, d, e, a, w1);		/* 33 */
			WUPDATE(w2, w15, w10, w4);	R2(a, b, c, d, e, w2);		/* 34 */
			WUPDATE(w3, w0, w11, w5);	R2(e, a, b, c, d, w3);		/* 35 */
			WUPDATE(w4, w1, w12, w6);	R2(d, e, a, b, c, w4);		/* 36 */
			WUPDATE(w5, w2, w13, w7);	R2(c, d, e, a, b, w5);		/* 37 */
			WUPDATE(w6, w3, w14, w8);	R2(b, c, d, e, a, w6);		/* 38 */
			WUPDATE(w7, w4, w15, w9);	R2(a, b, c, d, e, w7);		/* 39 */

			/* Round 3 */
			WUPDATE(w8, w5, w0, w10);	R3(e, a, b, c, d, w8);		/* 40 */
			WUPDATE(w9, w6, w1, w11);	R3(d, e, a, b, c, w9);		/* 41 */
			WUPDATE(w10, w7, w2, w12);	R3(c, d, e, a, b, w10);		/* 42 */
			WUPDATE(w11, w8, w3, w13);	R3(b, c, d, e, a, w11);		/* 43 */
			WUPDATE(w12, w9, w4, w14);	R3(a, b, c, d, e, w12);		/* 44 */
			WUPDATE(w13, w10, w5, w15);	R3(e, a, b, c, d, w13);		/* 45 */
			WUPDATE(w14, w11, w6, w0);	R3(d, e, a, b, c, w14);		/* 46 */
			WUPDATE(w15, w12, w7, w1);	R3(c, d, e, a, b, w15);		/* 47 */
			WUPDATE(w0, w13, w8, w2);	R3(b, c, d, e, a, w0);		/* 48 */
			WUPDATE(w1, w14, w9, w3);	R3(a, b, c, d, e, w1);		/* 49 */
			WUPDATE(w2, w15, w10, w4);	R3(e, a, b, c, d, w2);		/* 50 */
			WUPDATE(w3, w0, w11, w5);	R3(d, e, a, b, c, w3);		/* 51 */
			WUPDATE(w4, w1, w12, w6);	R3(c, d, e, a, b, w4);		/* 52 */
			WUPDATE(w5, w2, w13, w7);	R3(b, c, d, e, a, w5);		/* 53 */
			WUPDATE(w6, w3, w14, w8);	R3(a, b, c, d, e, w6);		/* 54 */
			WUPDATE(w7, w4, w15, w9);	R3(e, a, b, c, d, w7);		/* 55 */
			WUPDATE(w8, w5, w0, w10);	R3(d, e, a, b, c, w8);		/* 56 */
			WUPDATE(w9, w6, w1, w11);	R3(c, d, e, a, b, w9);		/* 57 */
			WUPDATE(w10, w7, w2, w12);	R3(b, c, d, e, a, w10);		/* 58 */
			WUPDATE(w11, w8, w3, w13);	R3(a, b, c, d, e, w11);		/* 59 */

			WUPDATE(w12, w9, w4, w14);	R4(e, a, b, c, d, w12);		/* 60 */
			WUPDATE(w13, w10, w5, w15);	R4(d, e, a, b, c, w13);		/* 61 */
			WUPDATE(w14, w11, w6, w0);	R4(c, d, e, a, b, w14);		/* 62 */
			WUPDATE(w15, w12, w7, w1);	R4(b, c, d, e, a, w15);		/* 63 */
			WUPDATE(w0, w13, w8, w2);	R4(a, b, c, d, e, w0);		/* 64 */
			WUPDATE(w1, w14, w9, w3);	R4(e, a, b, c, d, w1);		/* 65 */
			WUPDATE(w2, w15, w10, w4);	R4(d, e, a, b, c, w2);		/* 66 */
			WUPDATE(w3, w0, w11, w5);	R4(c, d, e, a, b, w3);		/* 67 */
			WUPDATE(w4, w1, w12, w6);	R4(b, c, d, e, a, w4);		/* 68 */
			WUPDATE(w5, w2, w13, w7);	R4(a, b, c, d, e, w5);		/* 69 */
			WUPDATE(w6, w3, w14, w8);	R4(e, a, b, c, d, w6);		/* 70 */
			WUPDATE(w7, w4, w15, w9);	R4(d, e, a, b, c, w7);		/* 71 */
			WUPDATE(w8, w5, w0, w10);	R4(c, d, e, a, b, w8);		/* 72 */
			WUPDATE(w9, w6, w1, w11);	R4(b, c, d, e, a, w9);		/* 73 */
			WUPDATE(w10, w7, w2, w12);	R4(a, b, c, d, e, w10);		/* 74 */
			WUPDATE(w11, w8, w3, w13);	R4(e, a, b, c, d, w11);		/* 75 */
			WUPDATE(w12, w9, w4, w14);	R4(d, e, a, b, c, w12);		/* 76 */
			WUPDATE(w13, w10, w5, w15);	R4(c, d, e, a, b, w13);		/* 77 */
			WUPDATE(w14, w11, w6, w0);	R4(b, c, d, e, a, w14);		/* 78 */
			WUPDATE(w15, w12, w7, w1);	R4(a, b, c, d, e, w15);		/* 79 */
			a += g_cSHA1baseCode[0];
			
			if (((a) == 0)) {
				b += g_cSHA1baseCode[1];
				if ((b & 0xffff0000) == 0) {
					block[0] = wi[0];
					block[1] = wi[1];
					block[2] = wi[2];
					block[3] = wi[3];
					block[4] = wi[4];
					block[5] = wi[5];
					block[6] = wi[6];
					block[7] = wi[7];
					block[8] = wi[8];
					block[9] = wi[9];
					block[10] = wi[10];
					block[11] = wi[11];
					block[12] = wi[12];
					block[13] = wi[13];
					block[14] = wi[14];
					block[15] = wi[15];

					(*ret_block) = (blockIdx.x << 5) + threadIdx.x;
					return;
				}
			}
			if ((*ret_block) != -1)
				return;

			break;
		}
	}
}
#include <random>
#include <chrono>

int main(int argc, char **argv)
{
	__u32 buf[5];
	SHA1Init(buf);
	sha_transformINIT(buf, (unsigned char*)argv[1]);
	
	std::default_random_engine generator(std::chrono::system_clock::now().time_since_epoch().count());
	std::uniform_int_distribution<int> distribution(33, 126);

	unsigned char data[2048 * 64];
	for (int j = 0; j < 2048; j++) {
		for (int i = 0; i < 56; i++)
			data[j*64 + i] = distribution(generator);

		data[j * 64 + 52] = 0x80;
		memset(j * 64 + data + 56, 0, 8);
		data[j * 64 + 61] = 0x03;
		data[j * 64 + 60] = 0xb8;
	}

	int iRetVal = -1;
    // Add vectors in parallel.
    cudaError_t cudaStatus = addWithCuda(buf, data, &iRetVal);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addWithCuda failed!");
        return 1;
    }
	for (int i = 0; i < 13; i++)
		for (int j = 3; j >= 0; j--)
			printf("%x ", data[iRetVal * 64 + (i << 2) + j]);
	printf("%x %x %x", data[iRetVal * 64 + 55], data[iRetVal * 64 + 54], data[iRetVal * 64 + 53]);

    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }

    return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t addWithCuda(__u32 SHA1Sum[], __u8 SHA1Data[], int *retVal)
{
	__u32 *dev_SHA1Data = 0;
	int *dev_retVal = 0;
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_SHA1Data, 2048 * 64 * sizeof(__u8));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

	cudaStatus = cudaMalloc((void**)&dev_retVal, sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpyToSymbol(g_cSHA1baseCode, SHA1Sum, 5 * sizeof(__u32));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpyToSymbol failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_SHA1Data, SHA1Data, 2048 * 64 * sizeof(__u8), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

	cudaStatus = cudaMemcpy(dev_retVal, retVal, sizeof(int), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

    // Launch a kernel on the GPU with one thread for each element.
	sha_transform <<<64, 32>>>(dev_retVal, dev_SHA1Data);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(SHA1Data, dev_SHA1Data, 2048 * 64 * sizeof(__u8), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(retVal, dev_retVal, sizeof(int), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

Error:
    cudaFree(dev_SHA1Data);
	cudaFree(dev_retVal);

    return cudaStatus;
}
