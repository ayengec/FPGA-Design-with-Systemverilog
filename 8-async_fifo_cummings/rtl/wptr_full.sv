// =============================================================================
// File        : wptr_full.sv
// Author      : Alican Yengec
// Description : Write Pointer Logic + Full Flag Generation
//
// Reference   : Clifford E. Cummings - "Simulation and Synthesis Techniques
//               for Asynchronous FIFO Design" (SNUG 2002)
//
// -----------------------------------------------------------------------------
// This module mirrors rptr_empty but for the write side. It maintains binary
// and gray-coded versions of the write pointer.
//
// Full Condition (Cummings):
//   The FIFO is full when the write pointer has "lapped" the read pointer —
//   meaning the writer has filled every slot and caught up to where the reader
//   is. In gray code, this is detected when:
//     1. The MSB of wptr does NOT match the MSB of rptr    (writer has lapped)
//     2. The 2nd MSB also does NOT match                   (confirms the lap)
//     3. All remaining bits DO match                       (same position)
//
//   In code: wnext == {~rptr[N:N-1], rptr[N-2:0]}
//
//   Why invert 2 bits instead of just 1? In gray code, a simple inversion of
//   only the MSB is not enough to detect the "lapped" state. Cummings proved
//   that inverting the top 2 MSBs and comparing the rest gives correct full
//   detection in gray code space.
//
//   Example (4-bit address, 5-bit pointer):
//     wptr_gray = 11000  (binary 10000 = position 16)
//     rptr_gray = 00000  (binary 00000 = position 0)
//     Invert top 2 of rptr: {~0,~0,000} = 11000
//     11000 == 11000 -> FULL!
//
//   Like the empty flag, this comparison is pessimistic — it uses the
//   synchronized (stale) read pointer, so it may report full when 1-2 slots
//   are actually free. This is intentionally SAFE: we might stall a write
//   briefly, but we will NEVER overflow and corrupt existing data.
//
// Reset Behavior:
//   On reset, both binary and gray pointers are cleared to 0, and wfull
//   is forced LOW (FIFO is not full after reset).
// =============================================================================

module wptr_full #(parameter ASIZE = 4) (
    output logic             wfull,     // FIFO full flag (registered output)
    output logic [ASIZE:0]   wptr,      // Gray-coded write pointer (sent to sync_w2r)
    input  logic [ASIZE:0]   wq2_rptr,  // Read pointer synced into wclk domain
    input  logic             winc,      // Write increment request from producer
    input  logic             wclk,      // Write clock
    input  logic             wrst_n     // Async reset (active-low)
);
    logic [ASIZE:0] wbin;               // Binary write pointer (current value)
    logic [ASIZE:0] wnext;              // Next gray-coded write pointer
    logic [ASIZE:0] wbinnext;           // Next binary write pointer
    logic wfull_val;                    // Combinational full flag (before register)

    // ---- Pointer Register ----
    // Captures the next binary and gray-coded pointer values on each wclk edge
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin <= 0;                  // Reset binary pointer to 0
            wptr <= 0;                  // Reset gray pointer to 0
        end else begin
            wbin <= wbinnext;           // Advance binary pointer
            wptr <= wnext;              // Advance gray pointer
        end
    end

    // ---- Binary Pointer Increment ----
    // Only increment when FIFO is not full AND the producer requests a write.
    assign wbinnext = wbin + (winc & ~wfull);
    
    // ---- Binary-to-Gray Conversion ----
    assign wnext = (wbinnext >> 1) ^ wbinnext;

    // ---- Full Condition ----
    // FIFO is FULL when the next write pointer (gray) matches the synchronized
    // read pointer with the top 2 bits inverted.
    assign wfull_val = (wnext == {~wq2_rptr[ASIZE:ASIZE-1], wq2_rptr[ASIZE-2:0]});

    // ---- Full Flag Register ----
    // Register the full flag to produce a clean, glitch-free output.
    // On reset, full is forced LOW (FIFO starts not-full).
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) 
            wfull <= 1'b0;     // FIFO is not full after reset
        else         
            wfull <= wfull_val;
    end
endmodule
