class axi_driver extends uvm_driver #(axi_item);
  `uvm_component_utils(axi_driver)

  virtual axi_if vif;

  function new(string name="axi_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "axi_driver: vif not set")
  endfunction

  task drive_idle();
    vif.awvalid <= 0;  vif.awaddr  <= 0;
    vif.wvalid  <= 0;  vif.wdata   <= 0;  vif.wstrb <= 0;
    vif.bready  <= 1;
    vif.arvalid <= 0;  vif.araddr  <= 0;
    vif.rready  <= 1;
  endtask

  task run_phase(uvm_phase phase);
    axi_item tr;

    drive_idle();
    wait (vif.rst_n === 1'b0);
    @(posedge vif.clk);
    drive_idle();
    wait (vif.rst_n === 1'b1);
    @(posedge vif.clk);

    forever begin
      seq_item_port.get_next_item(tr);

      if (tr.kind == WRITE) do_write(tr);
      else                  do_read(tr);

      seq_item_port.item_done();
    end
  endtask

  task do_write(axi_item tr);
    @(posedge vif.clk);

    // drive both channels (DUT accepts any order)
    vif.awaddr  <= tr.addr;
    vif.awvalid <= 1'b1;

    vif.wdata   <= tr.wdata;
    vif.wstrb   <= tr.wstrb;
    vif.wvalid  <= 1'b1;

    while (!(vif.awvalid && vif.awready)) @(posedge vif.clk);
    vif.awvalid <= 1'b0;

    while (!(vif.wvalid && vif.wready)) @(posedge vif.clk);
    vif.wvalid <= 1'b0;

    // wait B
    while (!vif.bvalid) @(posedge vif.clk);
    tr.resp = vif.bresp;

    @(posedge vif.clk); // complete handshake (bready held 1)
  endtask

  task do_read(axi_item tr);
    @(posedge vif.clk);

    vif.araddr  <= tr.addr;
    vif.arvalid <= 1'b1;

    while (!(vif.arvalid && vif.arready)) @(posedge vif.clk);
    vif.arvalid <= 1'b0;

    while (!vif.rvalid) @(posedge vif.clk);
    tr.rdata = vif.rdata;
    tr.resp  = vif.rresp;

    @(posedge vif.clk); // rready held 1
  endtask

endclass

