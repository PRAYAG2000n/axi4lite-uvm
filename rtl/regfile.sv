module regfile #(
  parameter int NREG = 16
) (
  input  logic        clk,
  input  logic        rst_n,

  input  logic        wr_en,
  input  logic [3:0]  wr_idx,
  input  logic [31:0] wr_data,
  input  logic [3:0]  wr_strb,

  input  logic [3:0]  rd_idx,
  output logic [31:0] rd_data
);

  logic [31:0] regs [NREG];

  // Combinational read
  always_comb begin
    rd_data = regs[rd_idx];
  end

  // Synchronous write with byte strobes
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < NREG; i++) regs[i] <= '0;
    end else if (wr_en) begin
      logic [31:0] cur;
      cur = regs[wr_idx];

      if (wr_strb[0]) cur[7:0]   = wr_data[7:0];
      if (wr_strb[1]) cur[15:8]  = wr_data[15:8];
      if (wr_strb[2]) cur[23:16] = wr_data[23:16];
      if (wr_strb[3]) cur[31:24] = wr_data[31:24];

      regs[wr_idx] <= cur;
    end
  end

endmodule

