// =============================================================================
// File        : rptr_empty.sv
// Author      : Alican Yengec
// Description : Read Pointer Logic + Empty Flag Generation
//
// Reference   : Clifford E. Cummings - SNUG 2002 (Async FIFO Design)
//
// -----------------------------------------------------------------------------
// This module maintains two versions of the read pointer:
//   1. Binary (rbin)  — used for incrementing and memory addressing
//   2. Gray   (rptr)  — used for safe cross-domain synchronization
//
// The binary counter increments when rinc is asserted AND the FIFO is NOT
// empty. The gray code is then derived from the binary using the standard
// conversion formula: gray = (binary >> 1) ^ binary.
//
// Empty Condition (Cummings):
//   The FIFO is empty when the NEXT gray-coded read pointer equals the
//   synchronized write pointer (rq2_wptr). Since the synchronized write 
//   pointer is always 2 rclk cycles behind the actual write pointer, this
//   comparison is *pessimistic* — it may report empty when 1-2 words
//   actually exist in the FIFO.
//
//   This is intentionally SAFE: we might stall a read for a cycle or two,
//   but we will NEVER read garbage data from an actually-empty FIFO.
//   In CDC design, safety always trumps performance.
//
// Reset Behavior:
//   On reset, both binary and gray pointers are cleared to 0, and rempty
//   is forced HIGH (FIFO is empty after reset). This matches the initial
//   state of the write pointer, so both sides agree the FIFO is empty.
// =============================================================================

module rptr_empty #(parameter ASIZE = 4) (
    output logic             rempty,    // FIFO empty flag (registered output)
    output logic [ASIZE:0]   rptr,      // Gray-coded read pointer (sent to sync_r2w)
    input  logic [ASIZE:0]   rq2_wptr,  // Write pointer synced into rclk domain
    input  logic             rinc,      // Read increment request from consumer
    input  logic             rclk,      // Read clock
    input  logic             rrst_n     // Async reset (active-low)
);
    logic [ASIZE:0] rbin;               // Binary read pointer (current value)
    logic [ASIZE:0] rnext;              // Next gray-coded read pointer
    logic [ASIZE:0] rbinnext;           // Next binary read pointer
    logic rempty_val;                   // Combinational empty flag (before register)

    // ---- Pointer Register ----
    // Captures the next binary and gray-coded pointer values on each rclk edge
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin <= 0;                  // Reset binary pointer to 0
            rptr <= 0;                  // Reset gray pointer to 0
        end else begin
            rbin <= rbinnext;           // Advance binary pointer
            rptr <= rnext;              // Advance gray pointer
        end
    end

    // ---- Binary Pointer Increment ----
    // Only increment when FIFO is not empty AND the consumer requests a read.
    // The (rinc & ~rempty) guard prevents pointer advancement on empty reads.
    assign rbinnext = rbin + (rinc & ~rempty);
    
    // ---- Binary-to-Gray Conversion ----
    // Standard formula: gray = (binary >> 1) XOR binary
    // Example: binary 0110 -> shift right -> 0011 -> XOR 0110 -> gray 0101
    //          binary 0111 -> shift right -> 0011 -> XOR 0111 -> gray 0100
    // Notice: only 1 bit differs between consecutive gray values (0101 vs 0100)
    assign rnext = (rbinnext >> 1) ^ rbinnext;

    // ---- Empty Condition ----
    // FIFO is EMPTY when the next read pointer (gray) equals the synchronized
    // write pointer. Both are in gray code, both live in the rclk domain.
    assign rempty_val = (rnext == rq2_wptr);

    // ---- Empty Flag Register ----
    // Register the empty flag to produce a clean, glitch-free output.
    // On reset, empty is forced HIGH (FIFO starts empty).
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) 
            rempty <= 1'b1;    // FIFO is empty after reset
        else         
            rempty <= rempty_val;
    end
endmodule
