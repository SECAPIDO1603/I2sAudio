#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <irq.h>
#include <uart.h>
#include <console.h>
#include <generated/csr.h>

const TAM_ARRAY=3*44100/4;
char arrayaudio[3*44100/4];

// Definición de variables de configuración

void i2s_master(void)
{
	i2s_master_conf_res_write(0xf);
	i2s_master_conf_ratio_write(0x37);
	i2s_master_conf_en_write(1);
	i2s_master_conf_swap_write(1);
}

void my_busy_wait(unsigned int ms)
{
	timer0_en_write(0);
	timer0_reload_write(0);
	timer0_load_write(CONFIG_CLOCK_FREQUENCY/1000*ms);
	timer0_en_write(1);
	timer0_update_value_write(1);
	while(timer0_value_read()) timer0_update_value_write(1);
}

// Lectura de datos de UART y guardado en memoria

void i2s_send_data(void)
{

	for (int i =0; i<16384;i++){
		while(i2s_master_address_r_read() == 1);
		
			i2s_master_wr_addr_write(i);
			i2s_master_data_in_write(arrayaudio[i]);
			i2s_master_wr_en_write(1);
		}

}

int main(void)
{
	irq_setmask(0);
	irq_setie(1);
	uart_init();
	puts("\nCPU testing cain_test SoC\n");
	printf("Hola Mundo \n");

	for (int i=0;i<TAM_ARRAY;i++)
		uart_write(arrayaudio[i]);

	while(1) {
		i2s_master();
		i2s_send_data();
	}
	return 0;
}



