typedef enum bit { READ=0, WRITE=1 } rw_e;

class axi_item extends uvm_sequence_item;
  rand rw_e        kind;
  rand bit [31:0]  addr;
  rand bit [31:0]  wdata;
  rand bit [3:0]   wstrb;

  bit [31:0]       rdata;
  bit [1:0]        resp;

  // knobs to force error addressing
  rand bit force_misaligned;
  rand bit force_oor;

  constraint c_flags { !(force_misaligned && force_oor); }

  // wstrb only meaningful for writes; keep nonzero for writes
  constraint c_wstrb {
    if (kind == WRITE) wstrb inside {4'h1,4'h2,4'h4,4'h8,4'h3,4'h5,4'h6,4'h9,4'hA,4'hC,4'h7,4'hB,4'hD,4'hE,4'hF};
    else              wstrb == 4'h0;
  }

  // Address generation:
  constraint c_addr {
    if (!force_misaligned && !force_oor) {
      addr[31:6] == 0;
      addr[5:2] inside {[0:15]};
      addr[1:0] == 2'b00;
    }

    if (force_misaligned) {
      addr[31:6] == 0;
      addr[5:2] inside {[0:15]};
      addr[1:0] inside {2'b01, 2'b10, 2'b11};
    }

    if (force_oor) {
      // violate DUT range check by setting upper bits non-zero
      addr[31:6] != 0;
    }
  }

  `uvm_object_utils_begin(axi_item)
    `uvm_field_enum(rw_e, kind, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(wdata, UVM_ALL_ON)
    `uvm_field_int(wstrb, UVM_ALL_ON)
    `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_field_int(resp, UVM_ALL_ON)
    `uvm_field_int(force_misaligned, UVM_ALL_ON)
    `uvm_field_int(force_oor, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="axi_item");
    super.new(name);
    force_misaligned = 0;
    force_oor        = 0;
  endfunction
endclass

