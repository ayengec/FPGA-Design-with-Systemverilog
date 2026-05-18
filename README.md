# FPGA Design with SystemVerilog

Welcome to my repository of hardware design and verification projects! This repository contains a structured, progressive collection of RTL designs implemented purely in **SystemVerilog**, showcasing modern digital design practices, proper FSM architecture, and advanced Clock Domain Crossing (CDC) techniques.

## Project Structure

The projects are ordered from basic combinational logic to advanced end-to-end industrial communication protocols and synchronization mechanisms. 

| # | Project Name | Description | Key Concept Highlights |
|---|--------------|-------------|------------------------|
| 1 | **Multiplexer (2-in-1-out)** | Basic combinational logic | `always_comb`, Routing |
| 2 | **Up/Down Counter** | Sequential logic design | Synchronous resets, Edge detection |
| 3 | **Finite State Machine (FSM)** | Moore/Mealy machine examples | State transitions, Control logic |
| 4 | **UART Transmitter** | Asynchronous serial transmission | **Datapath / Control Path separation**, 2-Block FSM |
| 5 | **UART Receiver** | Serial data recovery and sampling | Over-sampling, Error detection (Parity/Stop) |
| 6 | **I2C Master** | Multi-device serial communication | Clock stretching, Bidirectional `inout` (SDA/SCL) |
| 7 | **SPI Master** | High-speed synchronous serial | CPOL/CPHA modes, Shift registers |
| 8 | **Async FIFO (Cummings)** | Multi-clock domain bridging | **CDC**, Gray Counters, 2FF Synchronizers, Dual-Port RAM |

## Architectural Highlights
* **Separation of Concerns:** Complex modules (like UART and Async FIFO) strictly separate the **Control Path** (State Machines determining logic flow) from the **Datapath** (Arithmetic, counters, and registers handling actual data). This prevents synthesis latches and resolves critical path timing issues.
* **Modern SystemVerilog Standards:** Utilization of `always_ff`, `always_comb`, strongly typed logic, and enumerations (`enum`) to ensure simulation/synthesis consistency (avoiding Verilog-95/2001 pitfalls).
* **Robust Synchronization:** The Async FIFO employs Clifford E. Cummings' renowned dual-clock architecture, utilizing Gray Code pointers and multi-stage synchronizers to safely pass data across asynchronous clock domains without metastability.

## Tech Stack & Tools
* **Language:** SystemVerilog (IEEE 1800)
* **Target Platforms:** Vendor-agnostic (Synthesizable for Xilinx, Intel/Altera, Gowin, ASIC flows)
* **Verification:** Comprehensive self-checking testbenches using Verilator / Xcelium / Questa.
