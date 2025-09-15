# AXI4-Lite Slave Verification Plan

## Supported behavior
- 16 x 32-bit registers mapped at 0x00..0x3C (step 4)
- AXI4-Lite single beat transfers
- AW and W may arrive in any order
- Backpressure supported via BREADY/RREADY
- Responses:
  - OKAY (2'b00) on legal aligned access
  - SLVERR (2'b10) on misaligned addr (addr[1:0]!=0) or out-of-range

## Checking
- Monitor reconstructs write (AW/W/B) and read (AR/R) transactions
- Scoreboard reference model updates regs using WSTRB
- Scoreboard checks RDATA and RRESP/BRESP

## Coverage
- Address bins 0..15
- Read/write mix
- WSTRB patterns: full, 1-hot, 2-byte patterns
- Error bins: misaligned, out-of-range

