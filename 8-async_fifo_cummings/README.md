# Asynchronous FIFO — Clock Domain Crossing (CDC)

Made by : Alican Yengec

A vendor-agnostic, silicon-proven Asynchronous FIFO in SystemVerilog for safe data transfer between two independent clock domains.

## Reference

The architecture is based on the industry-standard paper by **Clifford E. Cummings**:

> *"Simulation and Synthesis Techniques for Asynchronous FIFO Design"* — SNUG 2002

All RTL, testbench, and verification infrastructure in this repository are designed and written from scratch. The Cummings paper serves as the architectural reference for the Gray-code pointer and dual-flop synchronizer methodology.

## Architecture

```text
                 [WRITE DOMAIN: wclk]                  [READ DOMAIN: rclk]
                 --------------------                  -------------------

    wdata -----> +------------------+                  +------------------+ -----> rdata
    winc  -----> |                  |   [waddr]        |                  | -----> rempty
    wfull <----- |   Write Logic    |======+           |    Read Logic    | <----- rinc
                 |  (wptr_full)     |      |           |  (rptr_empty)    |
                 +------------------+      |           +------------------+
                        ||                 |                   ||
                     [wptr]                v                [rptr]
                   (Gray Code)      +---------------+     (Gray Code)
                        ||          | Dual-Port RAM |          ||
                        ||          |  (fifo_mem)   |          ||
                        ||          +---------------+          ||
                        ||                 ^                   ||
                        ||              [raddr]                ||
                        ||                                     ||
                        vv                                     vv
                 +------------------+                  +------------------+
                 |   Synchronizer   |                  |   Synchronizer   |
                 |   (sync_w2r)     |<=================|   (sync_r2w)     |
                 +------------------+   rq2_wptr       +------------------+
                                                          wq2_rptr
```

## How It Works

### The Problem
When data crosses between two unrelated clocks (`wclk` and `rclk`), flip-flops can enter **metastability** — an unstable state where the output is neither 0 nor 1. If a multi-bit binary counter (e.g., `0111 → 1000`, where 4 bits change simultaneously) is sampled during a transition, the synchronized result could be completely wrong (e.g., `1111` or `0000`).

### The Solution: Gray Code + 2-Flop Synchronizers
- **Gray code counters** guarantee that only **one bit changes** per increment. If a synchronizer samples mid-transition, the worst case is the old value (safe) or the new value (also safe) — never garbage.
- **2-stage flip-flop synchronizers** resolve metastability within one clock period. The second flop captures the clean, stable value.
- **Pessimistic flags**: Because the synchronized pointer is always 2 cycles stale, `wfull` and `rempty` are *conservative*. They may report full/empty when 1–2 slots are actually available. This is intentionally **safe** — the design will never overflow or underflow, it will only occasionally stall for a cycle.

### N-bit vs (N+1)-bit Pointers
The memory is addressed using the lower `N` bits of the pointer. However, the pointers themselves are `N+1` bits wide. This extra MSB allows the design to distinguish between a *completely full* FIFO and a *completely empty* one — both of which would otherwise look identical (read pointer == write pointer).

## File Hierarchy

```
async_fifo_cdc/
├── README.md
├── rtl/
│   ├── async_fifo.sv        # Top-level wrapper (instantiates all sub-modules)
│   ├── fifo_mem.sv           # Dual-port RAM (inferred, vendor-agnostic)
│   ├── sync_r2w.sv           # 2-flop synchronizer: Read ptr → Write domain
│   ├── sync_w2r.sv           # 2-flop synchronizer: Write ptr → Read domain
│   ├── rptr_empty.sv         # Read pointer + empty flag generation
│   └── wptr_full.sv          # Write pointer + full flag generation
├── tb/
│   └── async_fifo_tb.sv      # Directed, self-checking sanity testbench
├── obj_dir/                   # Verilator build artifacts (auto-generated)
└── async_fifo_tb.vcd          # Waveform dump (auto-generated after --trace run)
```

## Module Hierarchy

| Module | File | Role |
|--------|------|------|
| `async_fifo` | `async_fifo.sv` | Top-level wrapper. Connects all sub-modules. |
| `fifo_mem` | `fifo_mem.sv` | Dual-port RAM (inferred). 1 write port (wclk), 1 read port (combinational). |
| `sync_r2w` | `sync_r2w.sv` | 2-flop synchronizer: Read pointer → Write clock domain. |
| `sync_w2r` | `sync_w2r.sv` | 2-flop synchronizer: Write pointer → Read clock domain. |
| `wptr_full` | `wptr_full.sv` | Write pointer binary/gray logic + `wfull` flag generation. |
| `rptr_empty` | `rptr_empty.sv` | Read pointer binary/gray logic + `rempty` flag generation. |

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DSIZE` | 8 | Data bus width in bits |
| `ASIZE` | 4 | Address width. FIFO depth = 2^ASIZE (default: 16 entries) |

## Sanity Testbench

The `tb/async_fifo_tb.sv` file is a directed, self-checking testbench that validates the fundamental correctness of the FIFO. It is intentionally kept as a simple, portable SystemVerilog testbench — no UVM dependency.

### Clock Configuration
| Clock | Frequency | Period |
|-------|-----------|--------|
| `wclk` (Write) | 100 MHz | 10.0 ns |
| `rclk` (Read) | 73 MHz | 13.7 ns |

The frequencies are intentionally **incommensurate** (no common divisor) to exercise worst-case CDC timing relationships. This ensures the synchronizers are tested under realistic asynchronous conditions.

### Test Plan

| # | Test | What It Verifies |
|---|------|-----------------|
| 1 | Reset Behavior | After reset: `wfull=0`, `rempty=1` |
| 2 | Basic Write & Read | Write 8 known values, read back, compare each byte in order |
| 3 | Full Flag | Write exactly 16 entries (full depth), verify `wfull=1` |
| 4 | Empty Flag | Drain all entries, verify `rempty=1` |
| 5 | Simultaneous R/W | Parallel write+read for 20 cycles, no overflow/underflow |

### How to Run (Verilator + Surfer)

Install prerequisites via Homebrew (macOS) or your package manager:

```bash
brew install verilator surfer
```

**Compile & simulate with waveform dump:**
```bash
verilator --binary --timing --trace -sv -Wall -Wno-fatal \
    rtl/*.sv tb/async_fifo_tb.sv \
    --top-module async_fifo_tb -o sim_async_fifo

./obj_dir/sim_async_fifo        # generates async_fifo_tb.vcd
```

**View waveform:**
```bash
surfer async_fifo_tb.vcd
```

> [Surfer](https://surfer-project.org/) is a modern, Apple Silicon native waveform viewer (VCD/FST).

### Simulation Log
```
=========================================================
 Async FIFO Sanity Testbench
 Config: DSIZE=8, ASIZE=4 (Depth=16)
 Write Clock: 100 MHz | Read Clock: 73 MHz
=========================================================

--- TEST 1: Reset Behavior ---
[TEST 1] PASS: wfull should be 0 after reset
[TEST 1] PASS: rempty should be 1 after reset

--- TEST 2: Basic Write & Read (Data Integrity) ---
[TEST 2] PASS: Read[0] = 0xa0 (expected 0xa0)
[TEST 2] PASS: Read[1] = 0xa1 (expected 0xa1)
[TEST 2] PASS: Read[2] = 0xa2 (expected 0xa2)
[TEST 2] PASS: Read[3] = 0xa3 (expected 0xa3)
[TEST 2] PASS: Read[4] = 0xa4 (expected 0xa4)
[TEST 2] PASS: Read[5] = 0xa5 (expected 0xa5)
[TEST 2] PASS: Read[6] = 0xa6 (expected 0xa6)
[TEST 2] PASS: Read[7] = 0xa7 (expected 0xa7)

--- TEST 3: Full Flag Assertion ---
[TEST 3] PASS: wfull should be 1 after writing 16 entries

--- TEST 4: Empty Flag Assertion ---
[TEST 4] PASS: rempty should be 1 after reading all entries

--- TEST 5: Simultaneous Read & Write ---
[TEST 5] PASS: No overflow: wfull did not cause data loss
[TEST 5] PASS: No underflow: rempty did not cause read of garbage

=========================================================
 ALL TESTS PASSED (0 errors)
=========================================================
```

### Waveform Analysis Guide

After opening the VCD in Surfer, add the following signals to inspect the design behavior visually:

#### Signals to Add
| Signal | Domain | What to Look For |
|--------|--------|------------------|
| `wclk` | Write | 100 MHz clock — faster domain |
| `rclk` | Read | 73 MHz clock — slower, asynchronous to wclk |
| `wrst_n`, `rrst_n` | Both | Active-low resets. Should deassert cleanly before any data movement |
| `wdata[7:0]` | Write | Data bus — verify `0xA0..0xA7` pattern during TEST 2 |
| `rdata[7:0]` | Read | Must match `wdata` in FIFO order (first-in, first-out) |
| `winc` | Write | Write enable — pulses high for each write cycle |
| `rinc` | Read | Read enable — pulses high for each read cycle |
| `wfull` | Write | **Must go HIGH** when 16 entries are written (TEST 3) |
| `rempty` | Read | **Must go HIGH** after reset (TEST 1) and after full drain (TEST 4) |

#### What to Verify on the Waveform

1. **Reset Phase (0–100 ns):**
   - Both `wrst_n` and `rrst_n` are LOW → `rempty = 1`, `wfull = 0`.
   - No data movement (`winc = 0`, `rinc = 0`).

2. **TEST 2 — Data Integrity (~100–600 ns):**
   - `winc` pulses 8 times → `wdata` increments `0xA0, 0xA1, ... 0xA7`.
   - After synchronization latency (~2–3 rclk cycles), `rinc` begins.
   - `rdata` must mirror `wdata` in exact FIFO order.

3. **TEST 3 — Full Flag (~600–1200 ns):**
   - 16 consecutive writes fill the FIFO completely.
   - `wfull` transitions from `0 → 1` on the last write. This is the critical edge to find.

4. **TEST 4 — Empty Flag (~1200–1600 ns):**
   - All entries drained by `rinc` pulses.
   - `rempty` transitions from `0 → 1` on the last read.

5. **TEST 5 — Simultaneous R/W (~1600–2000 ns):**
   - Both `winc` and `rinc` are active simultaneously for 20 cycles.
   - `wfull` should **never** cause data loss (no dropped writes).
   - `rempty` should **never** cause garbage reads.
   - This region is the most interesting for observing CDC behavior — the two clock domains are interleaving freely.

> **Tip:** In Surfer, use `Ctrl + Scroll` to zoom into specific test regions. Look at the gap between `winc` and `rinc` activations in TEST 2 — that 2–3 cycle delay is the 2-flop synchronizer latency in action.
