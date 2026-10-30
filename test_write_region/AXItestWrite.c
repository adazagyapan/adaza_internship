
#include <stdio.h>
#include <stdlib.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "xil_types.h"
#include "unistd.h"


#define DATA_BYTES 256


void press_enter_to_continue(void){
    	 xil_printf("\r\nSpecify the outputs in VIO using Vivado, \r\nand then press ENTER in order to read the DDR data\r\n");

    	 char c = 0;
    	 while (c != '\r' && c != '\n'){
    		 c = inbyte();
    	 }
     }

uintptr_t get_address_vio(void){
	uintptr_t vio_addr = 0;
	xil_printf("\n\rEnter the base address for VIO in hex\r\n");
	printf("\r\n==========================\r\n");
	scanf("%lx", (unsigned long *)&vio_addr);
	printf("Address Received: 0x%08lX\r\n",(unsigned long)vio_addr);
	return vio_addr;
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

    const uintptr_t base_address = get_address_vio();

    volatile u32 *ddr_ptr = (volatile u32 *)base_address;

    if (!write_test(ddr_ptr, base_address)) {
    	printf("Region is not writable\r\n");
    	cleanup_platform();
    	return -1;
    }

    else {
		// to clear the window first
		for (int i = 0; i < DATA_BYTES/4; i++) {
			ddr_ptr[i] = 0x00000000;
		}

		xil_printf("\r\n%d bytes at 0x%lX cleared\r\n", DATA_BYTES, (unsigned long) base_address);

		press_enter_to_continue();


		xil_printf("\r\n==========================\r\n");
		xil_printf("PL to PS DDR Data Verification Read\r\n");
		xil_printf("===============================\r\n");


		volatile u32 *ddr_pointer = (volatile u32 *)base_address;


		for (int i = 0; i < DATA_BYTES/4; i++) {
			printf("Address[0x%08lX]: ddr_ptr[%d]: Hex[0x%08X] : Decimal[%d]\r\n", (unsigned long)(base_address + i*4), i, ddr_pointer[i], ddr_pointer[i]);
		}

		xil_printf("\r\n--- PS DDR Read is Completed ---\r\n");


		cleanup_platform();
		return 0;
    }
}


