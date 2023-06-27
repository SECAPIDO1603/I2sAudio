`timescale 1ns / 10ps

module dpram #(
   parameter DATA_WIDTH=16,
   parameter RAM_WIDTH=14,
   parameter mem_file_sound="initsound.men"
   )
   (
      clk    ,
      rst    ,
      din    ,
      wr_en  ,
      rd_en  ,
      wr_addr,
      rd_addr,
      dout   
   );
   
input clk;
input rst;         
input[DATA_WIDTH - 1 : 0] din;
input wr_en;
input rd_en;
input[RAM_WIDTH - 1 : 0] wr_addr;
input[RAM_WIDTH - 1 : 0] rd_addr;
output[DATA_WIDTH - 1 : 0] dout;

// Palabra de 16 bits

reg[DATA_WIDTH - 1 : 0] dout;

// Registro de 16 bits con 16384 direcciones
         
reg[15: 0] memory [16383: 0];

   
always@(posedge clk)         
         if (wr_en) begin
         //   memory[wr_addr] <= din;
         end      
   

always@(posedge clk) 
//  if(rst)
//    dout<=0;
  if (rd_en) begin
      dout <= memory[rd_addr];
  end

// Lectura del archivo de audio

initial begin
	if (mem_file_sound == "initsound.men")
		$readmemh(mem_file_sound, memory);
end

endmodule
