// =============================================================================
// File        : fifo_mem.sv
// Author      : Alican Yengec
// Description : Simple Dual-Port RAM (1 write port, 1 read port)
//
// Reference   : Clifford E. Cummings - SNUG 2002 (Async FIFO Design)
//
// -----------------------------------------------------------------------------
// This module infers a dual-port memory in both FPGA (Block RAM / Distributed
// RAM) and ASIC (register file or compiled SRAM) flows. It does NOT use any
// vendor-specific primitives (no Xilinx XPM, no Gowin IP, no Intel Megafunction),
// ensuring full portability across all FPGA vendors and ASIC standard cell libs.
//
// Write Behavior:
//   Synchronous write on the rising edge of wclk, gated by wclken.
//   The write enable (wclken) is externally gated by (winc && ~wfull) so that
//   writes are automatically blocked when the FIFO is full.
//
// Read Behavior:
//   Combinational (asynchronous) read. Data appears on rdata as soon as raddr
//   changes, without waiting for a clock edge. This gives "First Word Fall
//   Through" (FWFT) behavior — when the FIFO transitions from empty to
//   non-empty, the first word is immediately available on rdata without
//   needing to assert rinc first.
//
// Synthesis Notes:
//   - On Gowin FPGAs: This will infer BSRAM (Block SRAM) or LUT-based
//     distributed RAM depending on the depth and the synthesizer's heuristics.
//   - On Xilinx: Infers BRAM or LUTRAM depending on depth.
//   - On ASIC: Synthesizes as a register file. For large depths, replace
//     this with a compiled SRAM macro from your foundry's memory compiler.
// =============================================================================

module fifo_mem #(
    parameter DSIZE = 8,                // Data width in bits
    parameter ASIZE = 4                 // Address width (depth = 2^ASIZE)
)(
    input  logic             wclk,      // Write clock
    input  logic             wclken,    // Write enable (gated by full logic)
    input  logic [ASIZE-1:0] waddr,     // Write address (N bits, no MSB)
    input  logic [DSIZE-1:0] wdata,     // Write data
    input  logic [ASIZE-1:0] raddr,     // Read address (N bits, no MSB)
    output logic [DSIZE-1:0] rdata      // Read data (combinational output)
);
    localparam DEPTH = 1<<ASIZE;        // e.g., ASIZE=4 -> DEPTH=16
    logic [DSIZE-1:0] mem [0:DEPTH-1];  // Memory array declaration

    // Synchronous write: data is captured on the rising edge of wclk
    // only when the write enable is active
    always_ff @(posedge wclk) begin
        if (wclken)
            mem[waddr] <= wdata;
    end

    // Asynchronous (combinational) read: no clock dependency
    // rdata updates immediately when raddr changes
    assign rdata = mem[raddr];
endmodule
