`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ayengec
// Engineer: ayengec
// 
// Create Date: 14.05.2021 14:20:02
// Design Name: uart_top_tb
// Module Name: uart_top_tb.sv
// Project Name: uart_transmitter
// Target Devices: Artix-7
// Tool Versions: 2020.1
// Description: Testbench for uart_top.sv. After reset state, 
// two data inserted to design with delay as 0x76 and 0x3F 
// 
// Dependencies: BASYS-3
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define DATA_WIDTH_NUMBER 8
`define STOP_BITS_NUMBER  2

module uart_top_tb();
    logic clk;
    logic rst_n;
    logic tx_start;
    logic [`DATA_WIDTH_NUMBER-1:0] data_in;
    logic tx_dout;
    logic tx_done;

    uart_top DUT(clk, rst_n, tx_start, data_in, tx_dout, tx_done);

    initial begin
        rst_n = 0;   // first 100 us board is in reset state
        tx_start =0;
        #100us;
        rst_n = 1;
        
        data_in = 8'h76;
        tx_start =1;
        #200us;
        tx_start =0;

        #2ms;   // dummy wait for each data frame

        data_in = 8'h3F;
        tx_start =1;
        #200us;
        tx_start =0;
        
        #10ms;
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
