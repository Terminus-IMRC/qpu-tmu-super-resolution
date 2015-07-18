#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <vc4vec.h>

#include "hoshi_256x256.h"

static const uint32_t code[] = {
#include "main.qasm4.qasm.bin.hex"
};

static struct vc4vec_mem inmem, outmem, cmdmem, codemem;
static const int height = 256, width = 256;
static const int h = 1024, w = 1024;
static const int code_size = sizeof(code);

#define C_EXIT 0
#define C_VPMINIT 1
#define C_TMU 2
#define C_VPMFLUSH 3

int main()
{
	int i, j;
	uint32_t *p;
	float off_y, off_x;

	vc4vec_init();
	vc4vec_mem_alloc(&inmem, height * width * (32 / 8));
	vc4vec_mem_alloc(&outmem, h * w * (32 / 8));
	vc4vec_mem_alloc(&cmdmem, 3e6);
	vc4vec_mem_alloc(&codemem, code_size);

	memcpy(inmem.cpu_addr, image, height * width * (32 / 8));
	memcpy(codemem.cpu_addr, code, code_size);
	p = cmdmem.cpu_addr;

	off_y = 1.0 / (h - 1);
	off_x = 1.0 / (w - 1);
	*((float*)p) = off_y; p++;
	*((float*)p) = off_x; p++;

	for (i = 0; i < h; i ++) {
		for (j = 0; j < w / 16; j ++) {
			*p++ = C_VPMINIT;
			*p++ = C_TMU;
			*((float*)p) = off_y * i; p++;
			*p++ = inmem.gpu_addr | (0 << 4);
			*((float*)p) = off_x * j * 16; p++;
			*p++ = (1 << 31) | (height << 20) | (width << 8) | (0 << 7) | (1 << 4) | (1 << 2) | (1 << 0);

			*p++ = C_VPMFLUSH;
			*p++ = outmem.gpu_addr + (i * w + j * 16) * (32 / 8);
		}
	}
	*p++ = C_EXIT;

	launch_qpu_job(1024, cmdmem.gpu_addr, codemem.gpu_addr);

	p = outmem.cpu_addr;
	for (i = 0; i < h; i ++) {
		for (j = 0; j < w; j ++) {
			printf("0x%08x%c", p[i * w + j], j == w - 1 ? '\n' : ' ');
		}
	}

	vc4vec_finalize();
	return 0;
}
