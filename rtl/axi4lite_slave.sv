module axi4lite_slave (
  input  logic        clk,
  input  logic        rst_n,

  // Write Address Channel
  input  logic [31:0] s_axi_awaddr,
  input  logic        s_axi_awvalid,
  output logic        s_axi_awready,

  // Write Data Channel
  input  logic [31:0] s_axi_wdata,
  input  logic [3:0]  s_axi_wstrb,
  input  logic        s_axi_wvalid,
  output logic        s_axi_wready,

  // Write Response Channel
  output logic [1:0]  s_axi_bresp,
  output logic        s_axi_bvalid,
  input  logic        s_axi_bready,

  // Read Address Channel
  input  logic [31:0] s_axi_araddr,
  input  logic        s_axi_arvalid,
  output logic        s_axi_arready,

  // Read Data Channel
  output logic [31:0] s_axi_rdata,
  output logic [1:0]  s_axi_rresp,
  output logic        s_axi_rvalid,
  input  logic        s_axi_rready
);

  localparam int NREG = 16;

  // ---- BUILD STAMP (Questa 10.7c safe) ----
  initial $display("### AXI4LITE_SLAVE BUILD STAMP: AXI4LITE_V2_XSAFE ###");

  // Regfile connections
  logic        rf_wr_en;
  logic [3:0]  rf_wr_idx;
  logic [31:0] rf_wr_data;
  logic [3:0]  rf_wr_strb;

  logic [3:0]  rf_rd_idx;
  logic [31:0] rf_rd_data;

  regfile #(.NREG(NREG)) u_rf (
    .clk     (clk),
    .rst_n   (rst_n),
    .wr_en   (rf_wr_en),
    .wr_idx  (rf_wr_idx),
    .wr_data (rf_wr_data),
    .wr_strb (rf_wr_strb),
    .rd_idx  (rf_rd_idx),
    .rd_data (rf_rd_data)
  );

  // -------------------------
  // Helpers (X-safe)
  // -------------------------
  function automatic logic addr_misaligned(input logic [31:0] a);
    // if a has X/Z in [1:0], treat as misaligned (bad)
    return !(a[1:0] inside {2'b00});
  endfunction

  function automatic logic addr_in_range(input logic [31:0] a);
    // valid: 0x00..0x3C -> index 0..15 in [5:2]
    // X-safe using inside; any X in the compared bits -> returns 0
    if (!(a[31:6] inside {26'd0}))         return 1'b0;
    if (!(a[5:2]  inside {[0:NREG-1]}))    return 1'b0;
    return 1'b1;
  endfunction

  function automatic logic [3:0] addr_to_idx(input logic [31:0] a);
    return a[5:2];
  endfunction

  // =====================================================
  // WRITE path: capture AW and W in any order, then issue B
  // =====================================================
  logic        aw_seen, w_seen;
  logic [31:0] awaddr_q;
  logic [31:0] wdata_q;
  logic [3:0]  wstrb_q;

  always_comb begin
    s_axi_awready = rst_n && !aw_seen && !s_axi_bvalid;
    s_axi_wready  = rst_n && !w_seen  && !s_axi_bvalid;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      aw_seen      <= 1'b0;
      w_seen       <= 1'b0;
      awaddr_q     <= '0;
      wdata_q      <= '0;
      wstrb_q      <= '0;

      s_axi_bvalid <= 1'b0;
      s_axi_bresp  <= 2'b00;

      rf_wr_en     <= 1'b0;
      rf_wr_idx    <= '0;
      rf_wr_data   <= '0;
      rf_wr_strb   <= '0;
    end else begin
      rf_wr_en <= 1'b0; // default

      if (s_axi_awvalid && s_axi_awready) begin
        aw_seen  <= 1'b1;
        awaddr_q <= s_axi_awaddr;
      end

      if (s_axi_wvalid && s_axi_wready) begin
        w_seen   <= 1'b1;
        wdata_q  <= s_axi_wdata;
        wstrb_q  <= s_axi_wstrb;
      end

      if (aw_seen && w_seen && !s_axi_bvalid) begin
        logic bad;
        bad = addr_misaligned(awaddr_q) || !addr_in_range(awaddr_q);

        if (!bad) begin
          rf_wr_en    <= 1'b1;
          rf_wr_idx   <= addr_to_idx(awaddr_q);
          rf_wr_data  <= wdata_q;
          rf_wr_strb  <= wstrb_q;
          s_axi_bresp <= 2'b00; // OKAY
        end else begin
          s_axi_bresp <= 2'b10; // SLVERR
        end

        s_axi_bvalid <= 1'b1;
        aw_seen <= 1'b0;
        w_seen  <= 1'b0;
      end

      if (s_axi_bvalid && s_axi_bready) begin
        s_axi_bvalid <= 1'b0;
      end
    end
  end

  // =====================================================
  // READ path: capture AR, then issue R (1-cycle latency)
  // =====================================================
  logic        ar_pending;
  logic [31:0] araddr_q;
  logic        ar_bad_q;

  always_comb begin
    s_axi_arready = rst_n && !ar_pending && !s_axi_rvalid;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ar_pending   <= 1'b0;
      araddr_q     <= '0;
      ar_bad_q     <= 1'b0;

      rf_rd_idx    <= '0;

      s_axi_rvalid <= 1'b0;
      s_axi_rdata  <= '0;
      s_axi_rresp  <= 2'b00;
    end else begin
      // accept AR
      if (s_axi_arvalid && s_axi_arready) begin
        araddr_q   <= s_axi_araddr;
        ar_bad_q   <= addr_misaligned(s_axi_araddr) || !addr_in_range(s_axi_araddr);

        rf_rd_idx  <= addr_to_idx(s_axi_araddr);
        ar_pending <= 1'b1;
      end

      // respond 1 cycle later
      if (ar_pending && !s_axi_rvalid) begin
        if (!ar_bad_q) begin
          s_axi_rdata <= rf_rd_data;
          s_axi_rresp <= 2'b00; // OKAY
        end else begin
          s_axi_rdata <= 32'hDEAD_BEEF;
          s_axi_rresp <= 2'b10; // SLVERR
        end

        s_axi_rvalid <= 1'b1;
        ar_pending   <= 1'b0;
      end

      if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end

endmodule

