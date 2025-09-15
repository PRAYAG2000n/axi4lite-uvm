class axi_monitor extends uvm_component;
  `uvm_component_utils(axi_monitor)

  virtual axi_if vif;
  uvm_analysis_port #(axi_item) ap;

  bit [31:0] awaddr_q, wdata_q, araddr_q;
  bit [3:0]  wstrb_q;

  function new(string name="axi_monitor", uvm_component parent=null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "axi_monitor: vif not set")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(vif.mon_cb);

      if (!vif.rst_n) begin
        continue;
      end

      // capture address/data whenever handshakes occur
      if (vif.mon_cb.awvalid && vif.mon_cb.awready) awaddr_q = vif.mon_cb.awaddr;
      if (vif.mon_cb.wvalid  && vif.mon_cb.wready)  begin
        wdata_q = vif.mon_cb.wdata;
        wstrb_q = vif.mon_cb.wstrb;
      end

      if (vif.mon_cb.bvalid && vif.mon_cb.bready) begin
        axi_item tr = axi_item::type_id::create("mon_wr");
        tr.kind  = WRITE;
        tr.addr  = awaddr_q;
        tr.wdata = wdata_q;
        tr.wstrb = wstrb_q;
        tr.resp  = vif.mon_cb.bresp;
        ap.write(tr);
      end

      if (vif.mon_cb.arvalid && vif.mon_cb.arready) araddr_q = vif.mon_cb.araddr;

      if (vif.mon_cb.rvalid && vif.mon_cb.rready) begin
        axi_item tr = axi_item::type_id::create("mon_rd");
        tr.kind  = READ;
        tr.addr  = araddr_q;
        tr.rdata = vif.mon_cb.rdata;
        tr.resp  = vif.mon_cb.rresp;
        ap.write(tr);
      end
    end
  endtask
endclass

