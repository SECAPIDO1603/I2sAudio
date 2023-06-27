`timescale 1ns / 10ps

module i2s_topm	#( 
                   parameter  DATA_WIDTH=16,          
                   parameter  ADDR_WIDTH=15,
                   parameter  IS_RECEIVER=0
                 )
                 ( 
                 input wb_clk,
                 input wb_rst,
                 input [5:0] conf_res,
                 input [23:0] conf_ratio,
                 input conf_swap,
                 input conf_en,
                 input [15:0] data_in,
                 output [15:0] sample_dat_o,
                 input wr_en,
                 input [13:0] wr_addr,
                 output [13:0] address_r,
                 output evt_hsbf,
                 output evt_lsbf,
                 output i2s_sd_i,
                 output i2s_sck,
                 output i2s_ws,
                 output i2s_sd);


   
wire imem_rdwr;
wire [13:0] sample_addr_u ;
wire [15:0] sample_data ;
assign address_r = sample_addr_u;

      dpram #(
         .DATA_WIDTH(16),
         .RAM_WIDTH (14),
         .mem_file_sound("initsound.men")
      )
      TRANSMITTER_MEM(
         .clk     (wb_clk),
         .rst     (wb_rst),
         .din     (data_in),
         .wr_en   (wr_en),
         .rd_en   (imem_rdwr),
         .wr_addr (wr_addr),
         .rd_addr (sample_addr_u),
         .dout    (sample_data)
      );
      

     i2s_codec #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .IS_RECEIVER(0)
     )
     TRANSMITTER_DEC(
         .wb_clk     (wb_clk),
         .wb_rst     (wb_rst),
         .conf_res     (conf_res),
         .conf_ratio   (conf_ratio),
         .conf_swap    (conf_swap),
         .conf_en      (conf_en),
         .i2s_sd_i     (i2s_sd_i),         
         .sample_dat_i (sample_data),
         .sample_dat_o (sample_dat_o),
         .mem_rdwr     (imem_rdwr),
         .sample_addr  (sample_addr_u),
         .evt_hsbf     (evt_hsbf),
         .evt_lsbf     (evt_lsbf),
         .i2s_sd     (i2s_sd),
         .i2s_sck    (i2s_sck),
         .i2s_ws     (i2s_ws)
     );   

       
       
endmodule  

  
