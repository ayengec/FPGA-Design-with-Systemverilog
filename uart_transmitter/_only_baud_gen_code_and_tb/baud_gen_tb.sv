`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.05.2021 14:39:57
// Design Name: 
// Module Name: baud_gen_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module baud_gen_tb();
    logic  clk, rst_n, tx_clk, rx_clk;
    baudrate_generator#(115200) DUT(clk, rst_n, tx_clk, rx_clk);

    initial begin
        rst_n = 0;
        #100ns;
        rst_n = 1;
        #100ms;
        $finish;
    end

    initial begin             // To generate clock
        clk =0;              // initial value for clock is '0'
        forever begin           // endless loop SV
        clk = ~clk;     // assign itself with invert of previous value
        #5ns;                 
        end
    end
   
endmodule
