// tb/pkg/axi_sequences.sv
`ifndef AXI_SEQUENCES_SV
`define AXI_SEQUENCES_SV

class sanity_rw_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(sanity_rw_seq)

  function new(string name="sanity_rw_seq");
    super.new(name);
  endfunction

  task body();
    axi_item tr;

    for (int i=0; i<16; i++) begin
      // WRITE
      tr = axi_item::type_id::create("wr");
      start_item(tr);
      tr.kind  = WRITE;
      tr.addr  = (i << 2);
      tr.wdata = $urandom;
      tr.wstrb = 4'hF;
      tr.force_misaligned = 0;
      tr.force_oor        = 0;
      finish_item(tr);

      // READ
      tr = axi_item::type_id::create("rd");
      start_item(tr);
      tr.kind  = READ;
      tr.addr  = (i << 2);
      tr.force_misaligned = 0;
      tr.force_oor        = 0;
      finish_item(tr);
    end
  endtask
endclass


class random_rw_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(random_rw_seq)

  function new(string name="random_rw_seq");
    super.new(name);
  endfunction

  task body();
    axi_item tr;
    repeat (50) begin
      tr = axi_item::type_id::create("rand_tr");
      start_item(tr);
      assert(tr.randomize());
      finish_item(tr);
    end
  endtask
endclass


class negative_addr_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(negative_addr_seq)

  function new(string name="negative_addr_seq");
    super.new(name);
  endfunction

  task body();
    axi_item tr;

    repeat (10) begin
      tr = axi_item::type_id::create("oor_wr");
      start_item(tr);
      tr.kind = WRITE;
      tr.force_oor        = 1;
      tr.force_misaligned = 0;
      tr.wdata = $urandom;
      tr.wstrb = 4'hF;
      finish_item(tr);

      tr = axi_item::type_id::create("oor_rd");
      start_item(tr);
      tr.kind = READ;
      tr.force_oor        = 1;
      tr.force_misaligned = 0;
      finish_item(tr);
    end
  endtask
endclass


class misaligned_addr_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(misaligned_addr_seq)

  function new(string name="misaligned_addr_seq");
    super.new(name);
  endfunction

  task body();
    axi_item tr;

    repeat (10) begin
      tr = axi_item::type_id::create("mis_wr");
      start_item(tr);
      tr.kind = WRITE;
      tr.force_misaligned = 1;
      tr.force_oor        = 0;
      tr.wdata = $urandom;
      tr.wstrb = 4'hF;
      finish_item(tr);

      tr = axi_item::type_id::create("mis_rd");
      start_item(tr);
      tr.kind = READ;
      tr.force_misaligned = 1;
      tr.force_oor        = 0;
      finish_item(tr);
    end
  endtask
endclass


// ------------------------------------------------------------
// Full coverage seq (Questa 10.7c safe)
// - Sweeps all 16 regs
// - Hits all wstrb bins you defined
// - Reads all regs
// - Hits bad addr bucket using force_oor and force_misaligned
// ------------------------------------------------------------
class full_coverage_seq extends uvm_sequence #(axi_item);
  `uvm_object_utils(full_coverage_seq)

  function new(string name="full_coverage_seq");
    super.new(name);
  endfunction

  function bit [31:0] addr_from_idx(int idx);
    // idx 0..15 => addr 0x00..0x3C
    bit [31:0] a;
    a = idx;       // implicit cast to 32-bit packed
    a = a << 2;
    return a;
  endfunction

  task body();
    axi_item tr;

    // fixed-size array of patterns (15 patterns)
    bit [3:0] patterns [0:14];

    // full
    patterns[0]  = 4'hF;

    // onehot
    patterns[1]  = 4'h1;
    patterns[2]  = 4'h2;
    patterns[3]  = 4'h4;
    patterns[4]  = 4'h8;

    // twoB (your bins: {3,5,6,9,10,12})
    patterns[5]  = 4'h3;
    patterns[6]  = 4'h5;
    patterns[7]  = 4'h6;
    patterns[8]  = 4'h9;
    patterns[9]  = 4'hA;
    patterns[10] = 4'hC;

    // threeB (your bins: {7,11,13,14})
    patterns[11] = 4'h7;
    patterns[12] = 4'hB;
    patterns[13] = 4'hD;
    patterns[14] = 4'hE;

    // 1) Sweep all regs with all patterns: 16 * 15 = 240 writes
    for (int idx=0; idx<16; idx++) begin
      for (int p=0; p<15; p++) begin
        tr = axi_item::type_id::create("fc_wr");
        start_item(tr);
        tr.kind  = WRITE;
        tr.addr  = addr_from_idx(idx);
        tr.wdata = $urandom;
        tr.wstrb = patterns[p];
        tr.force_misaligned = 0;
        tr.force_oor        = 0;
        finish_item(tr);
      end
    end

    // 2) Read all regs: 16 reads
    for (int idx=0; idx<16; idx++) begin
      tr = axi_item::type_id::create("fc_rd");
      start_item(tr);
      tr.kind  = READ;
      tr.addr  = addr_from_idx(idx);
      tr.force_misaligned = 0;
      tr.force_oor        = 0;
      finish_item(tr);
    end

    // 3) Bad address bucket (out-of-range)
    repeat (5) begin
      tr = axi_item::type_id::create("fc_bad_wr_oor");
      start_item(tr);
      tr.kind = WRITE;
      tr.force_oor        = 1;
      tr.force_misaligned = 0;
      tr.wdata = $urandom;
      tr.wstrb = 4'hF;
      finish_item(tr);

      tr = axi_item::type_id::create("fc_bad_rd_oor");
      start_item(tr);
      tr.kind = READ;
      tr.force_oor        = 1;
      tr.force_misaligned = 0;
      finish_item(tr);
    end

    // 4) Bad address bucket (misaligned)
    repeat (5) begin
      tr = axi_item::type_id::create("fc_bad_wr_mis");
      start_item(tr);
      tr.kind = WRITE;
      tr.force_misaligned = 1;
      tr.force_oor        = 0;
      tr.wdata = $urandom;
      tr.wstrb = 4'hF;
      finish_item(tr);

      tr = axi_item::type_id::create("fc_bad_rd_mis");
      start_item(tr);
      tr.kind = READ;
      tr.force_misaligned = 1;
      tr.force_oor        = 0;
      finish_item(tr);
    end
  endtask
endclass

`endif

