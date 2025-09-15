`ifndef AXI_COVERAGE_SV
`define AXI_COVERAGE_SV

class axi_coverage extends uvm_component;
  `uvm_component_utils(axi_coverage)

  uvm_analysis_imp #(axi_item, axi_coverage) imp;

  int kind_s;      // 0=READ, 1=WRITE
  int addr_bin_s;  // 0..15 valid, 16 bad
  int wstrb_s;     // 0..15
  int resp_s;      // 0=OKAY, 2=SLVERR

  function bit bad_addr(bit [31:0] a);
    return (a[1:0] != 0) || !((a[31:6] == 0) && (a[5:2] < 16));
  endfunction

  covergroup cg;
    option.per_instance = 1;

    kind_cp : coverpoint kind_s { bins rd={0}; bins wr={1}; }

    addr_cp : coverpoint addr_bin_s {
      bins regs[] = {[0:15]};
      bins bad    = {16};
    }

    // These bins match what we will DIRECTLY generate in full coverage seq
    wstrb_cp : coverpoint wstrb_s {
      bins full     = {15};
      bins onehot[] = {1,2,4,8};
      bins twoB[]   = {3,5,6,9,10,12};
      bins threeB[] = {7,11,13,14};
    }

    resp_cp : coverpoint resp_s { bins okay={0}; bins slverr={2}; }

    // Only “legal” combinations are counted to make 90-100% achievable
    kind_addr_resp_x : cross kind_cp, addr_cp, resp_cp {
      ignore_bins valid_slverr = binsof(addr_cp.regs) && binsof(resp_cp.slverr);
      ignore_bins bad_okay     = binsof(addr_cp.bad)  && binsof(resp_cp.okay);
    }

    wr_addr_wstrb_x : cross kind_cp, addr_cp, wstrb_cp {
      ignore_bins for_reads = binsof(kind_cp.rd);
      ignore_bins bad_addr  = binsof(addr_cp.bad);
    }
  endgroup

  function new(string name="axi_coverage", uvm_component parent=null);
    super.new(name, parent);
    imp = new("imp", this);
    cg  = new();
  endfunction

  function void write(axi_item tr);
    kind_s = (tr.kind == READ) ? 0 : 1;

    if (bad_addr(tr.addr))
      addr_bin_s = 16;
    else
      addr_bin_s = int'(tr.addr[5:2]);

    wstrb_s = int'(tr.wstrb);
    resp_s  = int'(tr.resp);

    cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("FCOV",
      $sformatf("Functional coverage (axi_coverage.cg) = %0.2f%%", cg.get_coverage()),
      UVM_NONE)

    `uvm_info("FCOV_DETAIL",
      $sformatf("kind=%0.2f addr=%0.2f wstrb=%0.2f resp=%0.2f | kind_addr_resp=%0.2f wr_addr_wstrb=%0.2f",
        cg.kind_cp.get_coverage(),
        cg.addr_cp.get_coverage(),
        cg.wstrb_cp.get_coverage(),
        cg.resp_cp.get_coverage(),
        cg.kind_addr_resp_x.get_coverage(),
        cg.wr_addr_wstrb_x.get_coverage()),
      UVM_NONE)
  endfunction
endclass

`endif

