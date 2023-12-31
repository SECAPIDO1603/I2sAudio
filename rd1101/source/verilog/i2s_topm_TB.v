`timescale 1 ns /  100 ps
//`define IS_RECEIVER 

module i2s_TB();
	
parameter DATA_WIDTH=16;
parameter ADDR_WIDTH=6;


   reg wb_clk_o, wb_rst_o, wb_sel_o, wb_stb_o, wb_we_o,wb_cyc_o;
   wire wb_ack_i;
   wire rx_ack, tx_ack;
   wire tx_int_o,rx_int_o;
   reg[1:0] wb_bte_o;
   reg[2:0] wb_cti_o;
   reg[ADDR_WIDTH - 1:0] wb_adr_o;
   reg[DATA_WIDTH -1:0] wb_dat_o;  
   wire[DATA_WIDTH -1:0] rx_dat_i, tx_dat_i;  
   wire i2s_sd_tx, i2s_sck_rx, i2s_sck_tx, i2s_ws_rx, i2s_ws_tx;
   reg i2s_sd_rx;
   
   reg[DATA_WIDTH -1 : 0] send_to_rx_left,send_to_rx_right; 
   reg i2s_ws_rx_del;
   reg[5:0] i,ii,ik,ki;
   integer k;
   reg[DATA_WIDTH -1 : 0] read_data; 
   
   parameter[ADDR_WIDTH - 2:0] zero=0;   
   parameter[ADDR_WIDTH - 1:0] TX_BUF_BASE={1'b1,zero};
   parameter[ADDR_WIDTH - 1:0] TX_CONFIG = 0;
   parameter[ADDR_WIDTH - 1:0] RX_CONFIG = 0;
   parameter[ADDR_WIDTH - 1:0] TX_INTSTAT=1;
   parameter[ADDR_WIDTH - 1:0] RX_INTSTAT=1;
   parameter WRITE_TIMEOUT= 20;  //-- Max cycles to wait during write
   parameter READ_TIMEOUT = 20;  //-- Max cycles to wait during read
                                                  
//-- I2S receiver, master mode  
`ifdef IS_RECEIVER             
   i2s_topm #(   
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .IS_RECEIVER(1)
        )
      IRX32M (
         //-- Wishbone interface
         .wb_clk_i  (wb_clk_o),               
         .wb_rst_i  (wb_rst_o),               
         .wb_sel_i  (wb_sel_o),               
         .wb_stb_i  (wb_stb_o),       
         .wb_we_i   (wb_we_o),                
         .wb_cyc_i  (wb_cyc_o),               
         .wb_bte_i  (wb_bte_o),               
         .wb_cti_i  (wb_cti_o),               
         .wb_adr_i  (wb_adr_o[ADDR_WIDTH-1 : 0]),   
         .wb_dat_i  (wb_dat_o[DATA_WIDTH-1 : 0]),  
         .i2s_sd_i  (i2s_sd_rx),                
         .wb_ack_o  (rx_ack),                
         .wb_dat_o  (rx_dat_i),              
         .rx_int_o  (rx_int_o),              
         .i2s_sck_o (i2s_sck_rx),               
         .i2s_ws_o  (i2s_ws_rx),                
         .tx_int_o  (),                   
         .i2s_sd_o  ()
      );                  
`else    //-- I2S transmitter, master mode
    i2s_topm #(
         .DATA_WIDTH (DATA_WIDTH),
         .ADDR_WIDTH (ADDR_WIDTH),
         .IS_RECEIVER(0)
      )
      ITX32M(
         //-- Wishbone interface
         .wb_clk_i (wb_clk_o),                
         .wb_rst_i (wb_rst_o),                
         .wb_sel_i (wb_sel_o),                
         .wb_stb_i (wb_stb_o),        
         .wb_we_i  (wb_we_o),                 
         .wb_cyc_i (wb_cyc_o),                
         .wb_bte_i (wb_bte_o),                
         .wb_cti_i (wb_cti_o),                
         .wb_adr_i (wb_adr_o[ADDR_WIDTH-1 : 0]),    
         .wb_dat_i (wb_dat_o[DATA_WIDTH-1 : 0]),   
         .i2s_sd_i (),//--open,
         .wb_ack_o (tx_ack),                 
         .wb_dat_o (tx_dat_i),               
         .rx_int_o (),
         .tx_int_o (tx_int_o),               
         .i2s_sd_o (i2s_sd_tx),                 
         .i2s_sck_o(i2s_sck_tx),                
         .i2s_ws_o (i2s_ws_tx)
      );
`endif       

`ifdef IS_RECEIVER 
   assign wb_ack_i =rx_ack;
 `else
   assign wb_ack_i =tx_ack;
 `endif

//-- Clock process, 50Mhz Wishbone master freq.   
   always #(5) wb_clk_o = ~wb_clk_o;

//-- Main test process
`ifdef IS_RECEIVER
    //------------------------------------"*** Test of  master RX ***"-----------------   
   initial          
   begin    
      wb_clk_o <=1'b0;
      wb_rst_o <= 1'b1;                  //-- system reset
      wb_sel_o <= 1'b0;
      wb_stb_o <= 1'b0;
      wb_sel_o <= 1'b0;
      wb_we_o  <= 1'b0;
      wb_cyc_o <= 1'b0;
      wb_bte_o <= 2'b00;
      wb_cti_o <= 3'b000;
      wb_adr_o <= 0;
      wb_dat_o <= 0;
      read_data<=0;
      i<=0;
      ii<=0;
      ik<=0;
      ki<=0;
      k=0;
      i2s_sd_rx<=1'b0;
      #200;
      wb_rst_o <= 1'b0;   
//-----------write receiver configure register to enable recevier,
//-----------enable interrupts,16bit resolution,left channel is stored on odd addresses     
     //-- start cycle on positive edge
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o);         
         wb_adr_o <= RX_CONFIG;
         wb_dat_o[15:0] <=16'h3a1f;//--0011101000011111
         wb_we_o  <= 1'b1;
         wb_cyc_o <= 1'b1;
         wb_stb_o <= 1'b1;
         wb_sel_o <= 1'b1;
         ////-- wait for acknowledge         
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for write configure register!");
           $stop;
         end
         //-- release bus
         wb_adr_o <= 0;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b0;
         wb_cyc_o <= 1'b0;
         wb_stb_o <= 1'b0;
         wb_sel_o <= 1'b0;         
//---------------------------"Wait for receiver master LSBF interrupt"
     wait (rx_int_o==1'b1);//wait until rx_int_o='1';
     //-----------------------read rxintsta register to check for receiver LSBF interrupt
     wb_adr_o <= RX_INTSTAT;
     wb_we_o  <= 1'b0;
     wb_cyc_o <= 1'b1; 
     wb_stb_o <= 1'b1;
     wb_sel_o <= 1'b1;
     //-- wait for acknowledge            
     @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
     @(posedge wb_clk_o);        
     if (wb_ack_i != 1'b1) begin
       $display($time,"  %m  \t \t  Warning: No acknowledge recevied for read rxintstat register!");                  
       $stop;
     end       
      read_data = rx_dat_i;      
      //-- release bus
      wb_adr_o <= 0;
      wb_we_o  <= 1'b0;
      wb_cyc_o <= 1'b0;
      wb_stb_o <= 1'b0;
      wb_sel_o <= 1'b0;     
      if (read_data != 32'h00000001) begin      	  
      	  $display($time,"  %m  \t \t  Warning: read LSBF of rxintstat register error!");                  
      end
      	      
//------------------------- write rxintstat register to clear receiver LSBF interrupt
      @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o);         
         wb_adr_o <= RX_INTSTAT;
         wb_dat_o <= 32'h00000001;
         wb_we_o  <= 1'b1;
         wb_cyc_o <= 1'b1;
         wb_stb_o <= 1'b1;
         wb_sel_o <= 1'b1;
         //-- wait for acknowledge                 
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for write rxintstat register");                  
           $stop;
         end            
         //-- release bus
         wb_adr_o <= 0;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b0;
         wb_cyc_o <= 1'b0;
         wb_stb_o <= 1'b0;
         wb_sel_o <= 1'b0;

//----------------------"Wait for receiver master HSBF interrupt"
     @(posedge wb_clk_o);
     @(posedge wb_clk_o);
     wait (rx_int_o==1'b1);//wait until rx_int_o='1';
//-----------------------read rxintsta register to check for receiver HSBF interrupt
     wb_adr_o <= RX_INTSTAT;
     wb_we_o  <= 1'b0;
     wb_cyc_o <= 1'b1; 
     wb_stb_o <= 1'b1;
     wb_sel_o <= 1'b1;
     //-- wait for acknowledge            
      @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for read rxintstat register!");                  
           $stop;
         end         
      read_data = rx_dat_i;      
      //-- release bus
      wb_adr_o <= 0;
      wb_we_o  <= 1'b0;
      wb_cyc_o <= 1'b0;
      wb_stb_o <= 1'b0;
      wb_sel_o <= 1'b0;
      if (read_data != 32'h00000002) begin
      	  $display($time,"  %m  \t \t  Warning: read HSBF of rxintstat register error!");                  
      end
      	      
//------------------------- write rxintstat register to clear receiver HSBF interrupt
      @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o);         
         wb_adr_o <= RX_INTSTAT;
         wb_dat_o <= 32'h00000002;
          wb_we_o  <= 1'b1;
         wb_cyc_o <= 1'b1;
         wb_stb_o <= 1'b1;
         wb_sel_o <= 1'b1;
         //-- wait for acknowledge                  
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for write rxintstat register");                  
           $stop;
         end           
         //-- release bus
         wb_adr_o <= 0;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b0;
         wb_cyc_o <= 1'b0;
         wb_stb_o <= 1'b0;
         wb_sel_o <= 1'b0; 
            
//---------------------write RXEN of configure register to bit 0 to stop the process of receiver
      //-- start cycle on positive edge
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o);         
         wb_adr_o <= RX_CONFIG;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b1;
         wb_cyc_o <= 1'b1;
         wb_stb_o <= 1'b1;
         wb_sel_o <= 1'b1;
         //-- wait for acknowledge        
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for write configure register!");                  
           $stop;
         end               
         //-- release bus
         wb_adr_o <= 0;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b0;
         wb_cyc_o <= 1'b0;
         wb_stb_o <= 1'b0;
         wb_sel_o <= 1'b0; 
         
         #1000;
     
      $stop;
   end

//-----generate sending to receiver data
  always@ (posedge wb_clk_o)    
       i2s_ws_rx_del<=i2s_ws_rx;
    
  
  
  always@(posedge wb_clk_o or posedge wb_rst_o) 
  	if (wb_rst_o == 1'b1) begin
         send_to_rx_left<=0;
         i<=0;
    end else begin
    	if (i2s_ws_rx==1'b0 && i2s_ws_rx_del==1'b1) begin//----neg of i2s_ws_rx
    	   send_to_rx_left<=(32768 + i*497)*256;
    	   i<=i+1;
      end
    end
    
   always@(posedge wb_clk_o or posedge wb_rst_o) 
  	if (wb_rst_o == 1'b1) begin
         send_to_rx_right<=0;
         ik<=0;
    end else begin
    	if (i2s_ws_rx==1'b1 && i2s_ws_rx_del==1'b0) begin//----pos of i2s_ws_rx
    	   send_to_rx_right<=(32767 - ik*497)*256;
    	   ik<=ik+1;
      end
    end
    
  always@(negedge i2s_sck_rx or posedge wb_rst_o)   	  
    if (wb_rst_o == 1'b1) begin
      i2s_sd_rx<=0;      
      ki<=15;
      ii<=15;
    end else begin
    	 if (i2s_ws_rx==1'b1) begin
    	 	 i2s_sd_rx<=send_to_rx_left[ki];    	 	 
    	 	 ki<=ki-1;
    	 	 if (ki==0) begin    	 	 	 
    	 	 	 ki<=15;
    	 	 end
    	 end else if (i2s_ws_rx==1'b0) begin
    	 	 i2s_sd_rx<=send_to_rx_right[ii];    	 	 
    	 	 ii<=ii-1;
    	 	 if (ii==0) begin    	 	 	 
    	 	 	 ii<=15;
    	 	 end
    	 end
    end      
`else 
initial            
   begin      
      wb_clk_o <=1'b0;
      wb_rst_o <= 1'b1;                  //-- system reset
      wb_sel_o <= 1'b0;
      wb_stb_o <= 1'b0;
      wb_sel_o <= 1'b0;
      wb_we_o  <= 1'b0;
      wb_cyc_o <= 1'b0;
      wb_bte_o <= 2'b00;
      wb_cti_o <= 3'b000;
      wb_adr_o <= 0;
      wb_dat_o <= 0;
      read_data<=0;     
      #200;
      wb_rst_o <= 1'b0;
//------------------------------------------"*** Test of master TX ***"------------
//-----------------Fill up sample buffers with test signal
//-----------------ramp up in left, ramp down in right
       for (k=0;k<=15;k=k+1) begin                
      //---------------------------left channel
         //-- start cycle on positive edge
         @(posedge wb_clk_o);
         wb_adr_o <= TX_BUF_BASE + 2*k;//--TX_BUF_BASE + 2*k;
         wb_dat_o <= (32767 - k*497);//*16;
         wb_we_o  <= 1'b1;
         wb_cyc_o <= 1'b1;
         wb_stb_o <= 1'b1;
         wb_sel_o <= 1'b1;
         //-- wait for acknowledge         
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for write even address of buffer!");                                    
           $stop;
         end       
         //-- release bus
         wb_adr_o <= 0;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b0;
         wb_cyc_o <= 1'b0;
         wb_stb_o <= 1'b0;
         wb_sel_o <= 1'b0;
      
      //--------------------------- right channel
         //-- start cycle on positive edge
         @(posedge wb_clk_o);
         wb_adr_o <= TX_BUF_BASE + 2*k+1;
         wb_dat_o <= (32768 + k*497);//*16;
         wb_we_o  <= 1'b1;
         wb_cyc_o <= 1'b1;
         wb_stb_o <= 1'b1;
         wb_sel_o <= 1'b1;
         //-- wait for acknowledge         
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for write odd address of buffer!");                                                      
           $stop;
         end                
         //-- release bus
         wb_adr_o <= 0;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b0;
         wb_cyc_o <= 1'b0;
         wb_stb_o <= 1'b0;
         wb_sel_o <= 1'b0;        
      end    	      	      	
//--------------------"Enable transmitter master,enable interrupts,16 bit resolution";
//---------------------left channel is stored on even addresses      
      //-- start cycle on positive edge
         @(posedge wb_clk_o);
         wb_adr_o <= TX_CONFIG;
         wb_dat_o[15:0] <= 16'h3a1b;//--0011101010001011
         wb_we_o  <= 1'b1;
         wb_cyc_o <= 1'b1;
         wb_stb_o <= 1'b1;
         wb_sel_o <= 1'b1;
         //-- wait for acknowledge                  
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for write configure register!");                  
           $stop;
         end                
         //-- release bus
         wb_adr_o <= 0;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b0;
         wb_cyc_o <= 1'b0;
         wb_stb_o <= 1'b0;
         wb_sel_o <= 1'b0;     
           
//----------------------"Wait for transmitter master LSBF interrupt"
     wait  (tx_int_o==1'b1);
//-----------------------read txintsta register to check for transmitter LSBF interrupt
     wb_adr_o <= TX_INTSTAT;
     wb_we_o  <= 1'b0;
     wb_cyc_o <= 1'b1; 
     wb_stb_o <= 1'b1;
     wb_sel_o <= 1'b1;
     //-- wait for acknowledge            
       @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for read txintstat register!");                  
           $stop;
         end                    
      read_data = tx_dat_i;      
      //-- release bus
      wb_adr_o <= 0;
      wb_we_o  <= 1'b0;
      wb_cyc_o <= 1'b0;
      wb_stb_o <= 1'b0;
      wb_sel_o <= 1'b0;    
      if (read_data != 32'h00000001) begin
      	  $display($time,"  %m  \t \t  Warning: read LSBF of txintstat register error!");
      end
      	      
//------------------------- write txintstat register to clear transmitter LSBF interrupt
         @(posedge wb_clk_o);         
         wb_adr_o <= TX_INTSTAT;
         wb_dat_o <= 32'h00000001;
         wb_we_o  <= 1'b1;
         wb_cyc_o <= 1'b1;
         wb_stb_o <= 1'b1;
         wb_sel_o <= 1'b1;
         //-- wait for acknowledge         
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for write txintstat register");                  
           $stop;
         end            
         //-- release bus
         wb_adr_o <= 0;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b0;
         wb_cyc_o <= 1'b0;
         wb_stb_o <= 1'b0;
         wb_sel_o <= 1'b0;   
         
//----------------------"Wait for transmitter master HSBF interrupt"
     @(posedge wb_clk_o);
     @(posedge wb_clk_o);
     wait  (tx_int_o==1'b1);//wait until tx_int_o='1';
//-----------------------read txintsta register to check for transmitter HSBF interrupt
     wb_adr_o <= TX_INTSTAT;
     wb_we_o  <= 1'b0;
     wb_cyc_o <= 1'b1; 
     wb_stb_o <= 1'b1;
     wb_sel_o <= 1'b1;
     //-- wait for acknowledge      
       @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for read txintstat register!");                  
           $stop;
         end            
      read_data = tx_dat_i;      
      //-- release bus
      wb_adr_o <= 0;
      wb_we_o  <= 1'b0;
      wb_cyc_o <= 1'b0;
      wb_stb_o <= 1'b0;
      wb_sel_o <= 1'b0;     
      if (read_data != 32'h00000002) begin      	  
      	  $display($time,"  %m  \t \t  Warning: read HSBF of txintstat register error!");                  
      end
      	      
//------------------------- write txintstat register to clear transmitter HSBF interrupt
      @(posedge wb_clk_o);         
         wb_adr_o <= TX_INTSTAT;
         wb_dat_o <= 32'h00000002;
         wb_we_o  <= 1'b1;
         wb_cyc_o <= 1'b1;
         wb_stb_o <= 1'b1;
         wb_sel_o <= 1'b1;
         //-- wait for acknowledge         
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for write txintstat register");                  
           $stop;
         end              
         //-- release bus
         wb_adr_o <= 0;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b0;
         wb_cyc_o <= 1'b0;
         wb_stb_o <= 1'b0;
         wb_sel_o <= 1'b0;   
            
//---------------------write TXEN of configure register to bit 0 to stop the process of transmitter
      //-- start cycle on positive edge
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o);         
         wb_adr_o <= TX_CONFIG;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b1;
         wb_cyc_o <= 1'b1;
         wb_stb_o <= 1'b1;
         wb_sel_o <= 1'b1;
         //-- wait for acknowledge                  
         @(posedge wb_clk_o);//wait until rising_edge(wb_clk_o); 
         @(posedge wb_clk_o);        
         if (wb_ack_i != 1'b1) begin
           $display($time,"  %m  \t \t  Warning: No acknowledge recevied for write configure register!");                  
           $stop;
         end         
         //-- release bus
         wb_adr_o <= 0;
         wb_dat_o <= 0;
         wb_we_o  <= 1'b0;
         wb_cyc_o <= 1'b0;
         wb_stb_o <= 1'b0;
         wb_sel_o <= 1'b0; 
         
         #1000;
         
         $stop;
   end

`endif   
initial begin: TEST_CASE
  $dumpfile("i2s_TB.vcd");
  $dumpvars(-1, ITX32M);
end
endmodule
