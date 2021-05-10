`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.05.2021 17:51:48
// Design Name: up_down_counter_top
// Module Name: up_down_tb
// Project Name: up_down_counter_top
// Target Devices: 
// Tool Versions: 
// Description: Testbench of updown counter design
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module up_down_tb();

  logic clk_tb, rst_n_tb, dir_tb;
  logic [7:0] out_led_tb ; 
  
  up_down_counter_top DUT(.clk(clk_tb), .rst_n(rst_n_tb), .dir(dir_tb), .out_led(out_led_tb));
    // We instantiate an object from up_down_counter_top design as "DUT"
    // DUT.design_pin(tb_pin) 
  
  initial begin  // 
    //$dumpfile("dump.vcd"); // If you use EDAplay and questa sim, you must add these two lines
    //$dumpvars;
    rst_n_tb = 0; // stay in reset while starting
    dir_tb   = 1; // count to up direction
    #100ms;
    rst_n_tb = 1; // start system releasing reset
    #700ms;  // you chan change design's magic number as counter 10M value to get faster simulation
    dir_tb   = 0; // changes direction to down
    #700ms;

1    $finish;      // totaly, test is finished
  end

  initial begin             // To generate clock
    clk_tb =0;              // initial value for clock is '0'
    forever begin           // endless loop SV
      clk_tb = ~clk_tb;     // assign itself with invert of previous value
      #5ns;                 // half clock period for 
                            // clk = 0 in T/2
                            // clk = 1 another T/2
    end
  end

endmodule :up_down_tb
