module axi_sva (axi_if vif);

  property p_valid_stable(valid, ready);
    @(posedge vif.clk) disable iff (!vif.rst_n)
      valid && !ready |=> valid;
  endproperty

  a_awvalid_stable: assert property (p_valid_stable(vif.awvalid, vif.awready));
  a_wvalid_stable : assert property (p_valid_stable(vif.wvalid,  vif.wready));
  a_arvalid_stable: assert property (p_valid_stable(vif.arvalid, vif.arready));
  a_bvalid_stable : assert property (p_valid_stable(vif.bvalid,  vif.bready));
  a_rvalid_stable : assert property (p_valid_stable(vif.rvalid,  vif.rready));

endmodule

bind top_tb.axi_vif axi_sva u_axi_sva (top_tb.axi_vif);

