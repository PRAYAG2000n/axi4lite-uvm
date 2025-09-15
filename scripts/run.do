if {![info exists TEST]} { set TEST "sanity_rw_test" }
if {![info exists VERB]} { set VERB "UVM_MEDIUM" }

vsim -uvmcontrol=all -coverage -voptargs=+acc work.top_tb \
  +UVM_TESTNAME=$TEST +UVM_VERBOSITY=$VERB

view wave
add wave -r sim:/top_tb/*
add wave -r sim:/top_tb/axi_vif/*
add wave -r sim:/top_tb/dut/*

run -all

