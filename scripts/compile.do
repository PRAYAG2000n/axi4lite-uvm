transcript on
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

set ROOT .

# 1) interface first
vlog -sv -mfcu +acc -cover bcesft $ROOT/tb/axi_if.sv

# 2) UVM package TB (includes everything in tb/pkg)
vlog -sv -mfcu +acc -cover bcesft +incdir+$ROOT/tb/pkg $ROOT/tb/pkg/axi_pkg.sv

# 3) RTL
vlog -sv -mfcu +acc -cover bcesft $ROOT/rtl/regfile.sv
vlog -sv -mfcu +acc -cover bcesft $ROOT/rtl/axi4lite_slave.sv

# 4) top
vlog -sv -mfcu +acc -cover bcesft $ROOT/tb/top_tb.sv

