// =============================================================================
// File        : sync_w2r.sv
// Author      : Alican Yengec
// Description : 2-Flop Synchronizer — Write pointer into Read clock domain
//
// Reference   : Clifford E. Cummings - SNUG 2002 (Async FIFO Design)
//
// -----------------------------------------------------------------------------
// This module is structurally identical to sync_r2w, but synchronizes the
// write pointer (wptr) into the read clock domain (rclk). The read-side
// empty generation logic needs to know how far the writer has advanced,
// so it can determine whether there is valid data available to read.
//
// The 2-flop synchronizer introduces a guaranteed latency of 2 rclk cycles.
// This means the read side always sees a "stale" write pointer — it may
// think the FIFO is empty when 1-2 words are actually available. This is
// intentionally pessimistic and SAFE (we never read from an empty FIFO).
// =============================================================================

module sync_w2r #(parameter ASIZE = 4) (
    output logic [ASIZE:0] rq2_wptr,    // Synchronized output (2nd flop stage)
    input  logic [ASIZE:0] wptr,        // Gray-coded write pointer from wclk domain
    input  logic           rclk,        // Destination clock (read domain)
    input  logic           rrst_n       // Async reset (active-low)
);
    logic [ASIZE:0] rq1_wptr;           // First flop stage (may be metastable)

    // Shift register chain: wptr -> rq1_wptr -> rq2_wptr
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) 
            {rq2_wptr, rq1_wptr} <= 0;
        else         
            {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};
    end
endmodule
