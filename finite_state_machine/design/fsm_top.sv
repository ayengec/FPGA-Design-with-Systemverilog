`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.05.2021 12:29:20
// Design Name: fsm_top
// Module Name: fsm_top.sv
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


module fsm_top (
    input  logic clk, rst_n,
    input  logic [1:0] sw,
    
    output logic track_states, track_reset   // these represent whether state/reset is changed or not
  );

  // one-hot encoding
  enum bit [5:0] {              // enumeration type of SV
    Zero          = 6'b000000,  // hamming distance of each other is 2
    Start         = 6'b000011,  
    Running       = 6'b000101,
    Stop          = 6'b001001,
    Stopped       = 6'b010001,
    Reset         = 6'b100001
  } State, NextState;           // both State and NextState can ge all states above


  // always_ff because it depends on clock so this is sequential logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      State <= Zero;
    else
      State <= NextState;
  end
  
  // combinational logic
  always_comb begin
    // check this code with our state diagram
    // firstly, you should design the state diagram then it's easy to tell synthesizer!!!  
    // Don't forget it. Language is only translator between your brain and computer.
    
    NextState = State;

    track_states = 0;
    track_reset = 0;

    unique case (State)
      Zero:
        if (sw[0])      NextState = Start;
      Start:
        begin
          track_states = 1;
          if (!sw)      NextState = Running; // not(all of the sw elements are 0)
        end
      Running:
        begin
          track_states = 1;
          if (sw[0])    NextState = Stop;
        end
      Stop:
        if (!sw)        NextState = Stopped;  
      Stopped:
        if (sw[0])      NextState = Start;
        else if (sw[1]) NextState = Reset;
      Reset:
        begin
          track_reset = 1;
          if (!sw)      NextState = Zero;
        end
    endcase
  end

endmodule: fsm_top
