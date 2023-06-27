from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

class Verilog_I2Stop(Module,AutoCSR):
   def __init__(self, data):
   # Interfaz
      self.clk      = ClockSignal()
      self.rst      = ResetSignal()
      self.i2s_sd_i = data.i2s_sd_i
      self.i2s_sd_o = data.i2s_sd_o
      self.i2s_sck_o = data.i2s_sck_o
      self.i2s_ws_o = data.i2s_ws_o
   # registros solo lectura      
      self.rx_int_o  = CSRStatus()
   # Registros solo escritura 
      self.tx_int_o  = CSRStorage()     
   # Instanciación del módulo verilog     
      self.specials +=Instance("I2S_capsule", 
	        i_clk      = self.clk,
          	i_reset    = self.rst,
	        i_i2s_sd   = self.i2s_sd_i,
            	o_i2s_sd   = self.i2s_sd_o,
            	o_i2s_sck  = self.i2s_sck_o,
            	o_i2s_ws   = self.i2s_ws_o,
            	o_rx_int_o  = self.rx_data.status,
            	o_tx_int_o   = self.tx_int_o.storage,
	   )	   
      self.submodules.ev = EventManager()
      self.ev.ok = EventSourceProcess()
      self.ev.finalize()
