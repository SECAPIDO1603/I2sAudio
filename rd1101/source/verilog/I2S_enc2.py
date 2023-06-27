from migen import *
from migen.genlib.cdc import MultiReg
from litex.soc.interconnect.csr import *
from litex.soc.interconnect.csr_eventmanager import *

class Verilog_i2s_master(Module,AutoCSR):
   def __init__(self, pads):
   # Interfaz
      self.clk      = ClockSignal()
      self.rst      = ResetSignal()
      self.i2s_sd_i = pads.i2s_sd_i
      self.i2s_sd = pads.i2s_sd
      self.i2s_sck = pads.i2s_sck
      self.i2s_ws = pads.i2s_ws
   # registros solo lectura      
      self.sample_addr = CSRStatus(5)
      self.evt_hsbf= CSRStatus()
      self.evt_lsbf= CSRStatus()
      self.mem_rdwr = CSRStatus() 
      self.sample_dat_o = CSRStatus(16) 
   # Registros solo escritura 
      self.sample_dat_i = CSRStorage(16)
      self.conf_res = CSRStorage(6)
      self.conf_ratio = CSRStorage(24)
      self.conf_swap = CSRStorage()
      self.conf_en = CSRStorage()  
   # Instanciación del módulo verilog     
      self.specials +=Instance("i2s_codec", 
	        i_wb_clk      = self.clk,
           i_wb_rst    = self.rst,
	        i_i2s_sd_i   = self.i2s_sd_i,
	        i_conf_res   = self.conf_res.storage,
	        i_conf_ratio   = self.conf_ratio.storage,
	        i_conf_swap   = self.conf_swap.storage,
	        i_conf_en   = self.conf_en.storage,
	        i_sample_dat_i  = self.sample_dat_i.storage,
           o_sample_dat_o = self.sample_dat_o.status,
            	o_i2s_sd   = self.i2s_sd,
            	o_i2s_sck  = self.i2s_sck,
            	o_i2s_ws   = self.i2s_ws,
            	o_mem_rdwr = self.mem_rdwr.status,
            	o_sample_addr   = self.sample_addr.status,
            	o_evt_hsbf = self.evt_hsbf.status,
            	o_evt_lsbf = self.evt_lsbf.status,
	   )	   
      self.submodules.ev = EventManager()
      self.ev.ok = EventSourceProcess()
      self.ev.finalize()
