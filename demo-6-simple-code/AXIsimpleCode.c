
#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xil_types.h"
#include "unistd.h"


#define MAX_WORDS 4194304 //16*2^20/4 16mb because its 24 bits in vhdl


void press_enter_to_continue(void){
    	 xil_printf("\r\nSpecify the outputs in VIO using Vivado, \r\nand then press ENTER in order to read the DDR data\r\n");

    	 char c = 0;
    	 while (c != '\r' && c != '\n'){
    		 c = inbyte();
    	 }
     }

uintptr_t get_address_vio(const char *which){
	uintptr_t vio_addr = 0;
	xil_printf("\n\rEnter the %s base address for VIO in hex\r\n", which);
	printf("\r\n==========================\r\n");
	scanf("%lx", (unsigned long *)&vio_addr);
	printf("%s address Received: 0x%08lX\r\n",which, (unsigned long)vio_addr);
	return vio_addr;
}

u32 get_word_count(void) {
	u32 words = 0;
	xil_printf("\n\rEnter the number of words in decimal\r\n");
	scanf("%u", (unsigned int *)&words);
	printf("Word count received: %u (%u bytes)\r\n", words, words*4);
	return words;
}

int write_test(volatile u32 *p, uintptr_t base) {
	const u32 pattern = 0xA5A5A5A5;

	u32 saved = p[0]; //keep whatever is already there
	p[0] = pattern; //write a known value
	u32 readback = p[0]; // read the written known value
	p[0] = saved; // restore back original contents

	if (readback==pattern) {
		printf("Write test successful at 0x%08lX\r\n", base);
		return 1;
	}
	else{
		printf("Write test failed at 0x%08lX (wrote 0x%08X, read 0x%08X)", base, pattern, readback);
		return 0;
	}
}

int main()

{
    init_platform();
    Xil_DCacheDisable(); // so that we do not need to flush or invalidate the cache

    const uintptr_t write_base = get_address_vio("write");
    const uintptr_t read_base = get_address_vio("read");
    const u32 word_count = get_word_count();

    if (word_count == 0 || word_count > MAX_WORDS) {
    	printf("Word count out of range");
    	cleanup_platform();
    	return -1;
    }

    volatile u32 *ddr_ptr = (volatile u32 *)write_base;

    if (!write_test(ddr_ptr, write_base)) {
    	printf("Region is not writable\r\n");
    	cleanup_platform();
    	return -1;
    }

    else {

    	volatile u32 *wr = (volatile u32 *)write_base;
    	volatile u32 *rd = (volatile u32 *)read_base;

    	for (int i = 0; i<word_count; i++){
    		wr[i] = 0x00000000;
    	}


		xil_printf("\r\n%d bytes at 0x%lX cleared\r\n", word_count * 4, (unsigned long) write_base);

		for (int i = 0; i<word_count; i++){
		    		u32 test_data = 0xDEADBEEF;
		    		rd[i] = test_data;
		}

		xil_printf("\r\n%d bytes at 0x%lX DEADBEEFed\r\n", word_count * 4, (unsigned long) read_base);

		press_enter_to_continue();


		xil_printf("\r\n==========================\r\n");
		xil_printf("PL to PS DDR Data Verification Read\r\n");
		xil_printf("===============================\r\n");



		for (int i = 0; i < word_count; i++) {
			printf("Address[0x%08lX]: ddr_ptr[%d]: Hex[0x%08X] : Decimal[%d]\r\n", (unsigned long)(write_base + i*4), i, wr[i], wr[i]);
		}

		xil_printf("\r\n--- PS DDR Read is Completed ---\r\n");


		cleanup_platform();
		return 0;
    }
}


