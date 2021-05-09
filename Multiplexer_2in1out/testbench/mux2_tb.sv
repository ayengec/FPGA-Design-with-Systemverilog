`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ayengec.com
// Engineer: Alican Yengec 
// 
// Create Date: 08.05.2021 16:13:31
// Design Name: mux2_tb.sv
// Module Name: mux2_tb.sv
// Project Name: mux2_tb
// Target Devices: Artix-7 / BASYS-3 BOARD
// Tool Versions: 2020.1
// Description: Testbench for two inputs-one output basic multiplexer with always_comb 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mux2_tb();

  logic mux_in1, mux_in2 ,mux_sel, mux_out; // Testbench's pin names to catch pin states of design

    // We will learn better solution for thi pin assignments in "Systemverilog Interfaces".
    // This looks like a classical method now.
  mux2_top DUT(.mux_in1(mux_in1), .mux_in2(mux_in2), .mux_sel(mux_sel), .mux_out(mux_out));
    // We instantiate an object from mux2_top design as "DUT"
    // assume that it's a dispertion property of multipication process in math
    // DUT.mux_in1(mux_in1) DUT=Design Under Test and we give our testbech's value to its mux_in1 pin
    // DUT.design_pin(tb_pin) 
  
  initial begin
    //$dumpfile("dump.vcd"); // If you use EDAplay and questa sim, you must add these two lines
    //$dumpvars;
    mux_in1=0;
    mux_in2=0;
    mux_sel=1;
    $display("0 0 1 result y %0d", mux_out); // writes the result to Simulation Console.
                                             // similar to C language %d integer %s string ...
    #25ns;                    // delay 25 ns after change pins
    mux_in1=1;
    mux_in2=0;
    mux_sel=1;               
    $display("1 0 1 result y %0d", mux_out); // analyze whether the output changes. 
                                             // Repeat this cycle for each step
    #25ns;
    mux_in1=0;
    mux_in2=1;
    mux_sel=1;
    $display("0 1 1 result y %0d", mux_out);
    #25ns;
    mux_in1=0;
    mux_in2=1;
    mux_sel=0;
    $display("0 1 0 result y %0d", mux_out);
    #25ns;
    mux_in1=1;
    mux_in2=1;
    mux_sel=1;
    $display("1 1 1 result y %0d", mux_out);
    #5ns;

    // We could write this code with $random values and for 
    // loop but I prefer to undestand easily for you at first example. 
    // You can improve this code!

  end
endmodule
