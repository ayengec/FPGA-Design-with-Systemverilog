// =============================================================================
// File        : sync_r2w.sv
// Author      : Alican Yengec
// Description : 2-Flop Synchronizer — Read pointer into Write clock domain
//
// Reference   : Clifford E. Cummings - SNUG 2002 (Async FIFO Design)
//
// -----------------------------------------------------------------------------
// Theory:
// A signal crossing clock domains can be sampled during a transition, causing
// metastability (the flop output hovers between 0 and 1 for an indeterminate
// amount of time). The first flop resolves the metastability within one clock
// period. The second flop captures the resolved, stable value.
//
// Why Gray code? If we synchronized a raw binary counter, multiple bits could
// change simultaneously (e.g., 0111 -> 1000 = 4 bits change). A synchronizer
// sampling mid-transition could produce a completely wrong value (like 1111 or
// 0000). Gray code guarantees only 1 bit changes at a time, so even if
// metastability occurs on that single bit, the worst case is the OLD value
// (safe) or the NEW value (also safe). Never garbage.
// =============================================================================

module sync_r2w #(parameter ASIZE = 4) (
    output logic [ASIZE:0] wq2_rptr,    // Synchronized output (2nd flop stage)
    input  logic [ASIZE:0] rptr,        // Gray-coded read pointer from rclk domain
    input  logic           wclk,        // Destination clock (write domain)
    input  logic           wrst_n       // Async reset (active-low)
);
    logic [ASIZE:0] wq1_rptr;           // First flop stage (may be metastable)

    // Shift register chain: rptr -> wq1_rptr -> wq2_rptr
    // On reset, both stages are cleared to 0 (matching pointer reset value)
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) 
            {wq2_rptr, wq1_rptr} <= 0;
        else         
            {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
    end
endmodule
