module top_tb;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import axi_pkg::*;

  logic clk;
  logic rst_n;

  // 100 MHz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // active-low reset
  initial begin
    rst_n = 1'b0;
    repeat (10) @(posedge clk);
    rst_n = 1'b1;
  end

  axi_if axi_vif(.clk(clk), .rst_n(rst_n));

  axi4lite_slave dut (
    .clk(clk),
    .rst_n(rst_n),

    .s_axi_awaddr (axi_vif.awaddr),
    .s_axi_awvalid(axi_vif.awvalid),
    .s_axi_awready(axi_vif.awready),

    .s_axi_wdata  (axi_vif.wdata),
    .s_axi_wstrb  (axi_vif.wstrb),
    .s_axi_wvalid (axi_vif.wvalid),
    .s_axi_wready (axi_vif.wready),

    .s_axi_bresp  (axi_vif.bresp),
    .s_axi_bvalid (axi_vif.bvalid),
    .s_axi_bready (axi_vif.bready),

    .s_axi_araddr (axi_vif.araddr),
    .s_axi_arvalid(axi_vif.arvalid),
    .s_axi_arready(axi_vif.arready),

    .s_axi_rdata  (axi_vif.rdata),
    .s_axi_rresp  (axi_vif.rresp),
    .s_axi_rvalid (axi_vif.rvalid),
    .s_axi_rready (axi_vif.rready)
  );

  // Give UVM access to the interface
  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_vif);
    run_test(); // uses +UVM_TESTNAME=...
  end
endmodule

