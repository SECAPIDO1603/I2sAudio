`timescale 1ns / 10ps

module i2s_codec #(
   parameter DATA_WIDTH  = 16,
   parameter ADDR_WIDTH  = 15,
   parameter IS_RECEIVER = 0,
   parameter freq_hz = 25000000,
   parameter baud    = 115200)
   (
      wb_clk   ,
      wb_rst   ,
      conf_res    ,
      conf_ratio  ,
      conf_swap   ,
      conf_en     ,
      i2s_sd_i    ,
      sample_dat_i,
      sample_dat_o,
      mem_rdwr    ,
      sample_addr ,
      evt_hsbf    ,
      evt_lsbf    ,
      i2s_sd   ,
      i2s_sck   ,
      i2s_ws   
   );      

input wb_clk;     //-- Clock
input wb_rst;     //-- Reset
input[5:0] conf_res;  //-- Resolución de bits
input[23:0] conf_ratio;  //-- Ratio del divisor de frec.
input conf_swap;     //-- Indicador canal izquierdo
input conf_en  ;     //-- Enable general
input i2s_sd_i ;            
input[15:0] sample_dat_i;  //-- audio data
output[15:0] sample_dat_o;  //-- audio data
output mem_rdwr;     //-- Enable read/write en memoria
output[13:0] sample_addr;  //-- address
output evt_hsbf ;     //-- Parte alta del sample buf vacío o lleno
output evt_lsbf ;     //-- Parte baja del sample buf vacío o lleno
output i2s_sd ;     //-- I2S SD
output i2s_sck;     //-- I2S BCLK
output i2s_ws;    //-- I2S WS

parameter IDLE=0;
parameter WAIT_CLK=1;
parameter TRX_DATA=2;
parameter RX_WRITE=3;
parameter SYNC=4;

reg[16383:0] temp_data=2**(ADDR_WIDTH-1);
   

 reg i2s_clk_en;
 reg [23:0] clk_cnt;
 reg [13:0] adr_cnt;// Rango 0 a 2**(ADDR_WIDTH - 1) - 1
 reg [4:0] sd_ctrl;
 reg[5:0] bit_cnt, bits_to_trx; //Rango de 0 a 63;
 reg toggle,neg_edge, ws_pos_edge,ws_neg_edge;
 reg[DATA_WIDTH - 1 : 0] data_in;// (DATA_WIDTH - 1 downto 0);
 reg i2s_ws_o, new_word;
 reg imem_rdwr;
 wire receiver;
 reg[4:0] ws_cnt; // Rango 0 a 31;
 
 reg i2s_sd,evt_lsbf,evt_hsbf;
   
assign receiver = (IS_RECEIVER==1)?1'b1:1'b0;

parameter divisor = freq_hz/baud/16;

//-----------------------------------------------------------------
// Generador de reset
//-----------------------------------------------------------------
reg [15:0] enable16_counter;

wire    enable16;
assign  enable16 = (enable16_counter == 0);

always @(posedge clk)
begin
	if (wb_rst) begin
		enable16_counter <= divisor-1;
	end else begin
		enable16_counter <= enable16_counter - 1;
		if (enable16_counter == 0) begin
			enable16_counter <= divisor-1;
		end
	end
end

//-- Proceso para generar SCLK

always@(posedge wb_clk)
            if (conf_en ==1'b0) begin       //-- Deshabilitado
               i2s_clk_en <= 1'b0;
               clk_cnt    <= 0;
               neg_edge   <= 1'b0;
               toggle     <= 1'b0;
            end else begin                   //  -- Enable
               if (clk_cnt < (conf_ratio + 1)) begin
                  clk_cnt    <= (clk_cnt + 1);
                  i2s_clk_en <= 1'b0;
               end else begin
                  clk_cnt    <= 0;
                  i2s_clk_en <= 1'b1;
                  neg_edge   <= !neg_edge;
               end
              toggle <= neg_edge;
            end

assign i2s_sck = toggle;

//-- Proceso para generar WS

assign  i2s_ws = i2s_ws_o;
always@ (posedge wb_clk)
            if (conf_en == 1'b0) begin
               i2s_ws_o      <= 1'b0;
               ws_cnt      <= 0;
               ws_pos_edge <= 1'b0;
               ws_neg_edge <= 1'b0;
            end else begin
               if ((i2s_clk_en == 1'b1) && (toggle == 1'b1)) begin
                  if (ws_cnt < bits_to_trx) begin
                     ws_cnt <= ws_cnt + 1;
                  end else begin
                     i2s_ws_o <= !i2s_ws_o;
                     ws_cnt <= 0;
                     if (i2s_ws_o == 1'b1) begin
                        ws_neg_edge <= 1'b1;
                     end else begin
                        ws_pos_edge <= 1'b1;
                     end
                  end
               end else begin
                  ws_pos_edge <= 1'b0;
                  ws_neg_edge <= 1'b0;
               end
            end

//assign i2s_sck = conf_en;

//-- Proceso para transmisión, parámetro IS_RECEIVER en 0

assign  sample_addr  = adr_cnt[ADDR_WIDTH - 2:0];
assign  mem_rdwr     = imem_rdwr;
assign  sample_dat_o = data_in;

always@(posedge wb_clk)
         if (conf_en == 1'b0) begin          //-- Inicio Códec
            imem_rdwr   <= 1'b0;
            sd_ctrl     <= IDLE;
            data_in     <= 0;
            bit_cnt     <= 0;
            bits_to_trx <= 0;
            new_word    <= 1'b0;
            adr_cnt     <= 0;
            evt_lsbf    <= 1'b0;
            evt_hsbf    <= 1'b0;
            i2s_sd    <= 1'b0;
         end else begin
            case (sd_ctrl)
               IDLE : begin                     // Paso 1 ASM: Inicialización
                  imem_rdwr <= 1'b0;
                  if ((conf_res > 15) && (conf_res < 33)) begin
                     bits_to_trx <= conf_res - 1;
                  end else begin
                     bits_to_trx <= 15;
                  end
                  if (conf_en ==1'b1) begin
                     if ((ws_pos_edge == 1'b1 & conf_swap == 1'b1) ||
                        (ws_neg_edge == 1'b1 & conf_swap == 1'b0)) begin
                        if (receiver == 1'b1) begin       
                           sd_ctrl <= WAIT_CLK;
                        end else begin
                           imem_rdwr <= 1'b1;  //-- Leer primer dato
                           sd_ctrl   <= TRX_DATA;
                        end
                     end
                  end
               end
               WAIT_CLK : begin        // Paso si fuera emisor, se omite
                  adr_cnt  <= 0;
                  bit_cnt  <= 0;
                  new_word <= 1'b0;
                  data_in  <= 0;
                  if ((i2s_clk_en == 1'b1) && (neg_edge == 1'b0)) begin
                     sd_ctrl <= TRX_DATA;
                  end
               end
               TRX_DATA : begin         // / Paso 2 ASM: Transmisión serial
                  imem_rdwr <= 1'b0;
                  evt_hsbf  <= 1'b0;
                  evt_lsbf  <= 1'b0;                  
                  if ((ws_pos_edge == 1'b1) || (ws_neg_edge == 1'b1)) begin
                     new_word <= 1'b1;
                  end
                  
                  // Proceso de recepción, ignorar

                  if (receiver == 1'b1) begin
                     if ((i2s_clk_en == 1'b1) && (neg_edge == 1'b1)) begin
                           if ((bit_cnt < bits_to_trx) && (new_word == 1'b0)) begin
                              bit_cnt                        <= bit_cnt + 1;
                              data_in[bits_to_trx - bit_cnt] <= i2s_sd_i;
                           end else begin
                              imem_rdwr                      <= 1'b1;
                              data_in[bits_to_trx - bit_cnt] <= i2s_sd_i;
                              sd_ctrl                        <= RX_WRITE;
                           end                 
                     end
                  end

                  //-- Proceso de transmisión

                  if (receiver == 1'b0) begin
                        if ((i2s_clk_en == 1'b1) && (neg_edge == 1'b0)) begin
                           if ((bit_cnt < bits_to_trx) && (new_word == 1'b0)) begin
                              bit_cnt  <= bit_cnt + 1;
                              i2s_sd <= sample_dat_i[bits_to_trx - bit_cnt];
                           end else begin
                              bit_cnt <= bit_cnt + 1;
                              if (bit_cnt > bits_to_trx) begin
                                 i2s_sd <= 1'b0;
                              end else begin
                                 i2s_sd <= sample_dat_i[0];
                              end

                              // Contador de direcciones

                              imem_rdwr <= 1'b1;
                              adr_cnt   <= (adr_cnt + 1) % temp_data;
                              if (adr_cnt == 2**(ADDR_WIDTH - 2) - 1) begin
                                 evt_lsbf <= 1'b1;
                              end else begin
                                 evt_lsbf <= 1'b0;
                              end
                              if (adr_cnt == 2**(ADDR_WIDTH - 1) - 1) begin
                                 evt_hsbf <= 1'b1;
                              end else begin
                                 evt_hsbf <= 1'b0;
                              end
                              sd_ctrl <= SYNC;
                           end
                        end                     
                  end
               end   
               RX_WRITE : begin         // Paso si fuera emisor, se omite
                  imem_rdwr <= 1'b0;
                  adr_cnt   <= (adr_cnt + 1) % temp_data;
                  if (adr_cnt == 2**(ADDR_WIDTH - 2) - 1) begin
                     evt_lsbf <= 1'b1;
                  end else begin
                     evt_lsbf <= 1'b0;
                  end
                  if (adr_cnt == 2**(ADDR_WIDTH - 1) - 1) begin
                     evt_hsbf <= 1'b1;
                  end else begin
                     evt_hsbf <= 1'b0;
                  end
                  sd_ctrl <= SYNC; 
               end
               SYNC : begin            // Paso 3 ASM: Sincronización nueva palabra
                  imem_rdwr <= 1'b0;
                  evt_hsbf  <= 1'b0;
                  evt_lsbf  <= 1'b0;
                  bit_cnt   <= 0;
                  if ((ws_pos_edge ==1'b1) || (ws_neg_edge == 1'b1)) begin
                     new_word <= 1'b1;
                  end  
                 
                  new_word <= 1'b0;
                  data_in  <= 0;
                  sd_ctrl  <= TRX_DATA;                     
               end               
               default: begin sd_ctrl  <=IDLE; end
            endcase
         end

endmodule
