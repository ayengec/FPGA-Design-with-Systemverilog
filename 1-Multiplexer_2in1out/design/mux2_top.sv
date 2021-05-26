`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ayengec.com
// Engineer: Alican Yengec 
// 
// Create Date: 08.05.2021 16:03:59
// Design Name: mux2_top.sv
// Module Name: mux2_top.sv
// Project Name: mux2_top
// Target Devices: Artix-7 / BASYS-3 BOARD
// Tool Versions: 2020.1
// Description: Two inputs-one output basic multiplexer with always_comb 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mux2_top(
    input  logic mux_in1, mux_in2, mux_sel, // 2 inputs for multiplexer and 1 input for selection pin
    output logic mux_out  // output for multiplexer
    );
    
    always_comb         // combinational logic process
    begin : Mux_block
    if (mux_sel)    // if mux_sel is HIGH (so TRUE)
        mux_out = mux_in2; // output mirrors the input2 pin
  	else            // if mux_sel is not HIGH (Z, X or 0)
        mux_out = mux_in1; // output mirrors the input1 pin
    end : Mux_block
endmodule
