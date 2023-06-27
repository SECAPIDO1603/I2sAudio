TARGET          = i2s_topm
PINS            = $(DESIGN).lpf
IVERILOG        = iverilog


SRC             = \
     $(TARGET).v i2s_codec.v dpram_rtl.v   \
	 gen_event_reg.v  rx_i2s_wbd.v  \
    gen_control_reg.v  tx_i2s_wbd.v
	 
SIM_SRC = $(TARGET)_TB.v   \


iversim: 
	$(IVERILOG) -gno-io-range-error -o i2s_TB.vvp $(VINCDIR) $(SRC) $(SIM_SRC) -s i2s_TB
	vvp i2s_TB.vvp; 
	gtkwave i2s_TB.vcd&
	
	all: $(TARGET).bit

remake:         clean-build all

clean:
	rm -rf *~ */*~ a.out *.log *.key *.edf *.json *.config *.vvp  *.svg *rpt
	rm -rf *.bit

cleanall: clean
	rm -rf build simulation/work simulation/transcript  simulation/vsim.wlf simulation/$(DESIGN)_TB.vvp simulation/*

#
# Synthesis
#

$(TARGET).json: $(SRC)
	yosys -p "verilog_defaults -push; verilog_defaults -add -defer; read_verilog $(SRC); verilog_defaults -pop; attrmap -tocase keep -imap keep="true" keep=1 -imap keep="false" keep=0 -remove keep=0; synth_ecp5 -top $(TARGET); write_json $@" -l ${TARGET}.rpt

$(TARGET)_out.config: $(TARGET).json
	nextpnr-ecp5 --json $< --lpf $(TARGET).lpf --textcfg $@ --25k --package CABGA256 --speed 6  --timing-allow-fail --seed 1 
#	nextpnr-ecp5 --json $< --lpf $(TARGET).lpf --textcfg $@ --25k --package CABGA381 --speed 6  --timing-allow-fail --seed 1 

$(TARGET).bit: $(TARGET)_out.config
	ecppack --bootaddr 0 --compress $< --svf ${TARGET}.svf --bit $@

${TARGET}.svf : ${TARGET}.bit

svg: $(SRC)
	yosys -p "prep -top ${TARGET}; write_json ${TARGET}.json" ${SRC}
	netlistsvg ${TARGET}.json -o ${TARGET}.svg  #--skin default.svg

configure: ${TARGET}.bit
	sudo openFPGALoader --cable ft232RL --pins=RXD:RTS:TXD:CTS $(TARGET).bit

