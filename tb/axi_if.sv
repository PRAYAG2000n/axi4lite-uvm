interface axi_if (input logic clk, input logic rst_n);

  logic [31:0] awaddr;  logic awvalid; logic awready;
  logic [31:0] wdata;   logic [3:0] wstrb; logic wvalid; logic wready;
  logic [1:0]  bresp;   logic bvalid; logic bready;

  logic [31:0] araddr;  logic arvalid; logic arready;
  logic [31:0] rdata;   logic [1:0] rresp; logic rvalid; logic rready;

  // Simple clocking blocks for monitoring convenience
  clocking mon_cb @(posedge clk);
    default input #1step output #1step;
    input awaddr, awvalid, awready;
    input wdata,  wstrb,  wvalid,  wready;
    input bresp,  bvalid, bready;
    input araddr, arvalid, arready;
    input rdata,  rresp,  rvalid,  rready;
  endclocking

endinterface

