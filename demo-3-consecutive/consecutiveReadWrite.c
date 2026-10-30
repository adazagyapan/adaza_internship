
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

u32 get_address_vio(void){
	u32 vio_addr = 0;
	xil_printf("\n\rEnter the base address for VIO (in hex with 8 digits)\r\n");
	printf("\r\n==========================\r\n");
	scanf("%x", (unsigned int *)&vio_addr);
	printf("Address Received: 0x%08X\r\n",vio_addr);
	return vio_addr;
}



int main()

{
    init_platform();
    Xil_DCacheDisable(); // so that we do not need to flush or invalidate the cache

    const u32 base_address = get_address_vio();

    volatile u32 *ddr_ptr = (volatile u32 *)(uintptr_t)base_address ;

    // to clear the window first
    for (int i = 0; i < DATA_BYTES/4; i++) {
        ddr_ptr[i] = 0x00000000;
    }

    xil_printf("\r\n%d bytes at 0x%x cleared\r\n");

	press_enter_to_continue();


    xil_printf("\r\n==========================\r\n");
	xil_printf("PL to PS DDR Data Verification Read\r\n");
	xil_printf("===============================\r\n");


	volatile u32 *ddr_pointer = (volatile u32 *)(uintptr_t)base_address;


    for (int i = 0; i < DATA_BYTES/4; i++) {
        printf("Address[0x%08X]: ddr_ptr[%d]: Hex[0x%08X] : Decimal[%d]\r\n",base_address + i*4, i, ddr_pointer[i], ddr_pointer[i]);
    }

	xil_printf("\r\n--- PS DDR Read is Completed ---\r\n");


	cleanup_platform();
	return 0;
}
