// tb/pkg/axi_tests.sv  (included inside axi_pkg package)
// Do NOT declare package here.
`ifndef AXI_TESTS_SV
`define AXI_TESTS_SV

class base_test extends uvm_test;
  `uvm_component_utils(base_test)
  axi_env env;

  function new(string name="base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi_env::type_id::create("env", this);
  endfunction
endclass


class sanity_rw_test extends base_test;
  `uvm_component_utils(sanity_rw_test)

  function new(string name="sanity_rw_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    sanity_rw_seq seq = sanity_rw_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.sqr);
    phase.drop_objection(this);
  endtask
endclass


class random_rw_test extends base_test;
  `uvm_component_utils(random_rw_test)

  function new(string name="random_rw_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    random_rw_seq seq = random_rw_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.sqr);
    phase.drop_objection(this);
  endtask
endclass


class negative_addr_test extends base_test;
  `uvm_component_utils(negative_addr_test)

  function new(string name="negative_addr_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    negative_addr_seq seq = negative_addr_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.sqr);
    phase.drop_objection(this);
  endtask
endclass


class misaligned_addr_test extends base_test;
  `uvm_component_utils(misaligned_addr_test)

  function new(string name="misaligned_addr_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    misaligned_addr_seq seq = misaligned_addr_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.sqr);
    phase.drop_objection(this);
  endtask
endclass


// This is the one you run to get 85–90%+
class full_coverage_test extends base_test;
  `uvm_component_utils(full_coverage_test)

  function new(string name="full_coverage_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    full_coverage_seq seq = full_coverage_seq::type_id::create("seq");
    phase.raise_objection(this);
    seq.start(env.agt.sqr);
    phase.drop_objection(this);
  endtask
endclass

`endif

