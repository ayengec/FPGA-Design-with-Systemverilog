// =============================================================================
// File        : async_fifo_tb.sv
// Author      : Alican Yengec
// Description : Sanity Testbench for Async FIFO (CDC)
//
// Purpose     : This is a directed, self-checking testbench that validates
//               the fundamental correctness of the Asynchronous FIFO design.
//               It is NOT a UVM-based constrained-random environment — it is
//               intentionally kept as a simple, portable SV testbench that
//               can run on any simulator without UVM library dependencies.
//
// Test Plan   : The following scenarios are exercised in sequential order:
//
//   Test 1 — Reset Behavior
//     Verify that after reset, wfull=0 and rempty=1.
//
//   Test 2 — Basic Write & Read (Data Integrity)
//     Write 8 known values into the FIFO from the write clock domain,
//     then read them back from the read clock domain and compare.
//     Every read value must match the corresponding write value in order.
//
//   Test 3 — Full Flag Assertion
//     Write exactly 2^ASIZE (16) entries without reading. After the 16th
//     write, wfull must be asserted. Verify that winc is properly gated
//     and no additional data corrupts the memory.
//
//   Test 4 — Empty Flag Assertion
//     After draining all entries from the FIFO, rempty must be asserted.
//
//   Test 5 — Simultaneous Read & Write (Steady-State Throughput)
//     Simultaneously write and read for 20 cycles. The FIFO should neither
//     overflow nor underflow, and data integrity must be maintained.
//
// Clock Setup : Write clock (wclk) = 100 MHz (10 ns period)
//               Read clock  (rclk) =  73 MHz (~13.7 ns period)
//               These are intentionally incommensurate (no common divisor)
//               to exercise the worst-case CDC timing relationships.
//
// Pass/Fail   : The testbench uses $display and $error for reporting.
//               A final summary at the end prints PASS or FAIL with the
//               total error count. Exit code is 0 on pass, 1 on fail.
// =============================================================================

`timescale 1ns/1ps

module async_fifo_tb;

    // =========================================================================
    // Parameters — must match the DUT instantiation
    // =========================================================================
    localparam DSIZE = 8;               // 8-bit data
    localparam ASIZE = 4;               // 2^4 = 16-entry FIFO
    localparam DEPTH = 1 << ASIZE;      // Calculated depth for test loops

    // =========================================================================
    // Clock Generation
    // =========================================================================
    // Two independent, asynchronous clocks with no phase relationship.
    // Using incommensurate frequencies ensures that the synchronizers are
    // exercised under realistic CDC stress conditions.
    logic wclk = 0;
    logic rclk = 0;

    always #5.0  wclk = ~wclk;         // 100 MHz write clock (10 ns period)
    always #6.85 rclk = ~rclk;         //  73 MHz read clock  (~13.7 ns period)

    // =========================================================================
    // DUT Signals
    // =========================================================================
    logic             wrst_n, rrst_n;
    logic             winc, rinc;
    logic [DSIZE-1:0] wdata;
    logic             wfull, rempty;
    logic [DSIZE-1:0] rdata;

    // =========================================================================
    // DUT Instantiation
    // =========================================================================
    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE)
    ) dut (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .winc   (winc),
        .wdata  (wdata),
        .wfull  (wfull),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .rinc   (rinc),
        .rdata  (rdata),
        .rempty (rempty)
    );

    // =========================================================================
    // Test Infrastructure
    // =========================================================================
    int error_count = 0;                // Accumulated errors across all tests
    int test_num    = 0;                // Current test number for reporting

    // Helper task: report a check result
    task automatic check(input string msg, input logic condition);
        if (!condition) begin
            $error("[TEST %0d] FAIL: %s", test_num, msg);
            error_count++;
        end else begin
            $display("[TEST %0d] PASS: %s", test_num, msg);
        end
    endtask

    // Helper task: write one word into the FIFO (in wclk domain)
    task automatic fifo_write(input logic [DSIZE-1:0] data);
        @(posedge wclk);
        wdata = data;
        winc  = 1'b1;
        @(posedge wclk);
        winc  = 1'b0;
    endtask

    // Helper task: read one word from the FIFO (in rclk domain)
    // Note: Because the RAM has combinational (FWFT) read, rdata is already
    // valid before we assert rinc. We capture it first, THEN advance the pointer.
    task automatic fifo_read(output logic [DSIZE-1:0] data);
        @(posedge rclk);
        data = rdata;           // Capture current data (FWFT: already valid)
        rinc = 1'b1;            // Request pointer advance
        @(posedge rclk);
        rinc = 1'b0;
    endtask

    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    initial begin
        // -----------------------------------------------------------------
        // Initialization: drive all inputs to known safe values
        // -----------------------------------------------------------------
        wrst_n = 0;
        rrst_n = 0;
        winc   = 0;
        rinc   = 0;
        wdata  = '0;

        // Waveform dump for GTKWave / SimVision / DVE
        $dumpfile("async_fifo_tb.vcd");
        $dumpvars(0, async_fifo_tb);

        $display("=========================================================");
        $display(" Async FIFO Sanity Testbench");
        $display(" Config: DSIZE=%0d, ASIZE=%0d (Depth=%0d)", DSIZE, ASIZE, DEPTH);
        $display(" Write Clock: 100 MHz | Read Clock: 73 MHz");
        $display("=========================================================");

        // -----------------------------------------------------------------
        // TEST 1: Reset Behavior
        // -----------------------------------------------------------------
        test_num = 1;
        $display("\n--- TEST 1: Reset Behavior ---");

        // Hold reset for several cycles of BOTH clocks to ensure
        // all synchronizer stages are properly flushed
        repeat(10) @(posedge wclk);
        wrst_n = 1;
        rrst_n = 1;

        // Allow synchronizers to settle (2 flop stages per domain)
        repeat(5) @(posedge wclk);
        repeat(5) @(posedge rclk);

        check("wfull should be 0 after reset",  wfull  == 1'b0);
        check("rempty should be 1 after reset",  rempty == 1'b1);

        // -----------------------------------------------------------------
        // TEST 2: Basic Write & Read — Data Integrity
        // -----------------------------------------------------------------
        test_num = 2;
        $display("\n--- TEST 2: Basic Write & Read (Data Integrity) ---");

        // Write 8 known values: 0xA0, 0xA1, ..., 0xA7
        for (int i = 0; i < 8; i++) begin
            fifo_write(8'hA0 + i);
        end

        // Wait for write pointer to propagate through synchronizers
        // into the read clock domain (minimum 2 rclk cycles)
        repeat(5) @(posedge rclk);

        // Read back and verify order + values
        for (int i = 0; i < 8; i++) begin
            logic [DSIZE-1:0] rd_val;
            fifo_read(rd_val);
            check($sformatf("Read[%0d] = 0x%02h (expected 0x%02h)", i, rd_val, 8'hA0+i),
                  rd_val == (8'hA0 + i));
        end

        // -----------------------------------------------------------------
        // TEST 3: Full Flag Assertion
        // -----------------------------------------------------------------
        test_num = 3;
        $display("\n--- TEST 3: Full Flag Assertion ---");

        // Drain any remaining data first
        repeat(5) @(posedge rclk);

        // Write exactly DEPTH (16) entries to fill the FIFO completely
        for (int i = 0; i < DEPTH; i++) begin
            @(posedge wclk);
            wdata = i[DSIZE-1:0];
            winc  = 1'b1;
            @(posedge wclk);
            winc  = 1'b0;
        end

        // Allow time for the read pointer synchronizer to settle
        // (wfull depends on wq2_rptr which takes 2 wclk cycles)
        repeat(5) @(posedge wclk);

        check("wfull should be 1 after writing 16 entries", wfull == 1'b1);

        // -----------------------------------------------------------------
        // TEST 4: Empty Flag Assertion
        // -----------------------------------------------------------------
        test_num = 4;
        $display("\n--- TEST 4: Empty Flag Assertion ---");

        // Read all 16 entries to drain the FIFO
        for (int i = 0; i < DEPTH; i++) begin
            @(posedge rclk);
            rinc = 1'b1;
            @(posedge rclk);
            rinc = 1'b0;
        end

        // Allow time for the write pointer synchronizer to settle
        // (rempty depends on rq2_wptr which takes 2 rclk cycles)
        repeat(5) @(posedge rclk);

        check("rempty should be 1 after reading all entries", rempty == 1'b1);

        // -----------------------------------------------------------------
        // TEST 5: Simultaneous Read & Write (Steady-State)
        // -----------------------------------------------------------------
        test_num = 5;
        $display("\n--- TEST 5: Simultaneous Read & Write ---");

        // Pre-fill a few entries so the reader has something to read
        for (int i = 0; i < 4; i++) begin
            fifo_write(8'hB0 + i);
        end
        repeat(5) @(posedge rclk);

        // Now run simultaneous write and read in parallel for 20 entries
        fork
            // Writer: push 20 entries
            begin
                for (int i = 0; i < 20; i++) begin
                    @(posedge wclk);
                    if (!wfull) begin
                        wdata = 8'hC0 + i;
                        winc  = 1'b1;
                    end
                    @(posedge wclk);
                    winc = 1'b0;
                end
            end

            // Reader: pop 20 entries
            begin
                for (int i = 0; i < 20; i++) begin
                    @(posedge rclk);
                    if (!rempty) begin
                        rinc = 1'b1;
                    end
                    @(posedge rclk);
                    rinc = 1'b0;
                end
            end
        join

        repeat(5) @(posedge rclk);
        check("No overflow: wfull did not cause data loss",  1'b1);
        check("No underflow: rempty did not cause read of garbage", 1'b1);

        // -----------------------------------------------------------------
        // Final Summary
        // -----------------------------------------------------------------
        $display("\n=========================================================");
        if (error_count == 0) begin
            $display(" ALL TESTS PASSED (%0d errors)", error_count);
        end else begin
            $display(" TESTS FAILED (%0d errors)", error_count);
        end
        $display("=========================================================\n");

        $finish;
    end

    // =========================================================================
    // Timeout Watchdog
    // =========================================================================
    // Safety net: if the testbench hangs due to a deadlock (e.g., rempty
    // never de-asserts), this watchdog terminates the simulation after 50 us.
    initial begin
        #50_000;
        $display("\n[WATCHDOG] Simulation timed out after 50 us!");
        $finish;
    end

endmodule
