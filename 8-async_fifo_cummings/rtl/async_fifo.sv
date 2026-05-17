// =============================================================================
// File        : async_fifo.sv
// Author      : Alican Yengec
// Description : Asynchronous FIFO — Top-Level Wrapper (Clock Domain Crossing)
//
// Reference   : Clifford E. Cummings - "Simulation and Synthesis Techniques 
//               for Asynchronous FIFO Design" (SNUG 2002)
//
// -----------------------------------------------------------------------------
// Architecture Overview:
// -----------------------------------------------------------------------------
//
//                 [WRITE DOMAIN: wclk]                  [READ DOMAIN: rclk]
//                 --------------------                  -------------------
//
//    wdata -----> +------------------+                  +------------------+ -----> rdata
//    winc  -----> |                  |   [waddr]        |                  | -----> rempty
//    wfull <----- |   Write Logic    |======+           |    Read Logic    | <----- rinc
//                 |  (wptr_full)     |      |           |  (rptr_empty)    |
//                 +------------------+      |           +------------------+
//                        ||                 |                   ||
//                     [wptr]                v                [rptr]
//                   (Gray Code)      +---------------+     (Gray Code)
//                        ||          | Dual-Port RAM |          ||
//                        ||          |  (fifo_mem)   |          ||
//                        ||          +---------------+          ||
//                        ||                 ^                   ||
//                        ||              [raddr]                ||
//                        ||                                     ||
//                        vv                                     vv
//                 +------------------+                  +------------------+
//                 |   Synchronizer   |                  |   Synchronizer   |
//                 |   (sync_w2r)     |<=================|   (sync_r2w)     |
//                 +------------------+   (rq2_wptr)     +------------------+
//                                                          (wq2_rptr)
//
// -----------------------------------------------------------------------------
// Key Design Choices (per Cummings):
// -----------------------------------------------------------------------------
// 1. Gray Code Counters: Only one bit changes at a time, eliminating the risk
//    of synchronizing transitional multi-bit changes across clock domains.
//
// 2. N-bit vs (N+1)-bit Pointers: Memory is addressed using the lower N bits,
//    but pointers are (N+1) bits wide. The extra MSB allows us to distinguish
//    between a completely FULL FIFO and a completely EMPTY one. Without this
//    extra bit, both conditions would look identical (pointers equal).
//
// 3. Full/Empty Generation: These flags are generated in the clock domain of
//    the module that needs to act on them:
//      - `wfull`  is generated in the WRITE clock domain (wclk), because the
//        write logic must know when to STOP writing.
//      - `rempty` is generated in the READ clock domain (rclk), because the
//        read logic must know when to STOP reading.
//
// 4. 2-Flop Synchronizers: Each pointer crosses into the opposite clock domain
//    through a 2-stage flip-flop chain. This is the industry standard for
//    reducing metastability MTBF (Mean Time Between Failures) to acceptable
//    levels (typically > 100 years at modern process nodes).
// =============================================================================

module async_fifo #(
    parameter DSIZE = 8,    // Data width in bits
    parameter ASIZE = 4     // Address width (FIFO depth = 2^ASIZE = 16 entries)
)(
    // ---- Write Domain Interface ----
    input  logic             wclk,              // Write clock
    input  logic             wrst_n,            // Write reset (active-low, async)
    input  logic             winc,              // Write enable (increment pointer)
    input  logic [DSIZE-1:0] wdata,             // Write data bus
    output logic             wfull,             // FIFO full flag (in wclk domain)

    // ---- Read Domain Interface ----
    input  logic             rclk,              // Read clock
    input  logic             rrst_n,            // Read reset (active-low, async)
    input  logic             rinc,              // Read enable (increment pointer)
    output logic [DSIZE-1:0] rdata,             // Read data bus
    output logic             rempty             // FIFO empty flag (in rclk domain)
);

    // Internal gray-code pointers (N+1 bits wide)
    // These live in their respective clock domains
    logic [ASIZE:0] wptr, rptr;
    
    // Synchronized versions of the pointers after crossing domains
    // wq2_rptr = read pointer synchronized into wclk domain (2 flop delays)
    // rq2_wptr = write pointer synchronized into rclk domain (2 flop delays)
    logic [ASIZE:0] wq2_rptr, rq2_wptr;

    // ---------------------------------------------------------
    // Instantiation 1: Read-to-Write Synchronizer
    // Purpose: Bring the read pointer (rptr) from rclk domain 
    //          into wclk domain so we can generate wfull.
    // ---------------------------------------------------------
    sync_r2w #(ASIZE) sync_r2w_inst (
        .wq2_rptr (wq2_rptr), // Output: rptr after 2 wclk flops
        .rptr     (rptr),     // Input : Gray-coded read pointer (rclk domain)
        .wclk     (wclk),
        .wrst_n   (wrst_n)
    );

    // ---------------------------------------------------------
    // Instantiation 2: Write-to-Read Synchronizer
    // Purpose: Bring the write pointer (wptr) from wclk domain 
    //          into rclk domain so we can generate rempty.
    // ---------------------------------------------------------
    sync_w2r #(ASIZE) sync_w2r_inst (
        .rq2_wptr (rq2_wptr), // Output: wptr after 2 rclk flops
        .wptr     (wptr),     // Input : Gray-coded write pointer (wclk domain)
        .rclk     (rclk),
        .rrst_n   (rrst_n)
    );

    // ---------------------------------------------------------
    // Instantiation 3: Dual-Port RAM
    // Purpose: The actual storage element. One port writes 
    //          (wclk), one port reads (rclk). No arbitration 
    //          needed because read and write never target the 
    //          same address simultaneously (guaranteed by full/
    //          empty logic).
    // ---------------------------------------------------------
    fifo_mem #(DSIZE, ASIZE) fifo_mem_inst (
        .wclk  (wclk),
        .wclken(winc && ~wfull),        // Only write when not full
        .waddr (wptr[ASIZE-1:0]),       // Lower N bits = memory address
        .wdata (wdata),
        .raddr (rptr[ASIZE-1:0]),       // Lower N bits = memory address
        .rdata (rdata)
    );

    // ---------------------------------------------------------
    // Instantiation 4: Read Pointer + Empty Flag Generator
    // Purpose: Advances the read pointer on rinc, converts 
    //          binary to gray, and compares against the synced 
    //          write pointer to determine if FIFO is empty.
    // ---------------------------------------------------------
    rptr_empty #(ASIZE) rptr_empty_inst (
        .rempty   (rempty),
        .rptr     (rptr),               // Gray-coded read pointer output
        .rq2_wptr (rq2_wptr),           // Synced write ptr (for empty check)
        .rinc     (rinc),
        .rclk     (rclk),
        .rrst_n   (rrst_n)
    );

    // ---------------------------------------------------------
    // Instantiation 5: Write Pointer + Full Flag Generator
    // Purpose: Advances the write pointer on winc, converts 
    //          binary to gray, and compares against the synced 
    //          read pointer to determine if FIFO is full.
    // ---------------------------------------------------------
    wptr_full #(ASIZE) wptr_full_inst (
        .wfull    (wfull),
        .wptr     (wptr),               // Gray-coded write pointer output
        .wq2_rptr (wq2_rptr),           // Synced read ptr (for full check)
        .winc     (winc),
        .wclk     (wclk),
        .wrst_n   (wrst_n)
    );

endmodule
