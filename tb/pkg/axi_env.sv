class axi_env extends uvm_env;
  `uvm_component_utils(axi_env)

  axi_agent      agt;
  axi_scoreboard sb;
  axi_coverage   cov;

  function new(string name="axi_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = axi_agent     ::type_id::create("agt", this);
    sb  = axi_scoreboard::type_id::create("sb",  this);
    cov = axi_coverage  ::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.ap.connect(sb.imp);
    agt.ap.connect(cov.imp);
  endfunction
endclass

