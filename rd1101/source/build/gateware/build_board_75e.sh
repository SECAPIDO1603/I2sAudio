# Autogenerated by LiteX / git: 34ec22f8
set -e
yosys -l board_75e.rpt board_75e.ys
nextpnr-ecp5 --json board_75e.json --lpf board_75e.lpf --textcfg board_75e.config  --25k --package CABGA256 --speed 6 --timing-allow-fail --seed 1 
ecppack  --bootaddr 0   --compress  board_75e.config --svf board_75e.svf --bit board_75e.bit 