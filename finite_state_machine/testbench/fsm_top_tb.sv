`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.05.2021 12:31:59
// Design Name: fsm_top_tb
// Module Name: fsm_top_tb.sv
// Project Name: finite_state_machine
// Target Devices: Artix-7
// Tool Versions: 2020.1
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fsm_top_tb;

  logic clk, rst_n;
  logic [1:0] sw;
  logic track_states, track_reset;
  
  bit [1:0] rand_sw;

  parameter Period = 10;

  fsm_top DUT (clk, rst_n, sw, track_states, track_reset);

  initial begin      // clock gen block
    clk = 0;
    forever begin
       #(Period/2) clk = !clk;  // clock generation for 10 ns period
    end    
  end

  
  initial begin 
    rst_n = 0;  // start the design in reset state
    #10ns;
    rst_n = 1; 
    #5ns;
    for (int i=0; i<50; ++i) begin // random values are assigned into sw bit array
      sw = $urandom;
      #5ns;
    end
    
    $finish;

  end

endmodule
