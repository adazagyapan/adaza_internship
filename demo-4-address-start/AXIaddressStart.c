#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xil_types.h"
#include "unistd.h"

#define DATA_WORDS 64
#define DATA_BYTES (DATA_WORDS * 4)
#define DEADBEEF 0xDEADBEEF

void press_enter_to_continue(void) {
	xil_printf("\r\n\nStart read and/or write in the VIO, then press ENTER to read back from the DDR.\r\n");
	char c = 0;
	while (c != '\r' && c != '\n') {
		c = inbyte();
	}
}

u32 get_address(const char *which) {
	u32 addr = 0;
	xil_printf("\n\rEnter the %s base address in 8 digit hex\r\n", which);
	printf("=========================\r\n");
	scanf("%x", (unsigned int *)&addr);
	printf("%s address received: 0x%08X\r\n", which, addr);
	return addr;
}

void region(const char *label, u32 base) {
	volatile u32 *p = (volatile u32 *)(uintptr_t)base;
	xil_printf("%s at 0x%08X\r\n", label, base);
	xil_printf("=========================\r\n");
	for (int i=0; i<DATA_WORDS; i++) {
		printf("Address[0x%08X]: [%2d]: Hex[0x%08X]: Decimal[%d]\r\n", base + i*4, i, p[i], p[i]);
	}
}

int main() {
	init_platform();
	Xil_DCacheDisable();

	u32 write_base = get_address("write");
	u32 read_base = get_address("read");

	volatile u32 *wr = (volatile u32 *)(uintptr_t)write_base;
	volatile u32 *rd = (volatile u32 *)(uintptr_t)read_base;

	for (int i=0; i<DATA_WORDS; i++) {
		wr[i] = 0x00000000; // clear the write region
	}

	printf("\r\n%d bytes at 0x%08X cleared in write region\r\n", DATA_BYTES, write_base);
	printf("Read will pull from the address 0x%08X, data can be observed from ILA.\r\n", read_base);

	for (int i = 0; i<DATA_WORDS; i++) { // write DEADBEEF to read regions that arent used by write function
		rd[i] = DEADBEEF;
	}

	press_enter_to_continue();

	region("Readback from DDR", write_base);

	xil_printf("\r\n--- Write verified in DDR. Read completed, check the ILA. ---\r\n");

	cleanup_platform();
	return 0;
}
