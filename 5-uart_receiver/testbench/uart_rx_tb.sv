`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.05.2021 19:59:26
// Design Name: 
// Module Name: uart_rx_tb
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


`define DATA_WIDTH_NUMBER 8
`define STOP_BITS_NUMBER  2

module uart_rx_tb();

    logic data_in;
    logic clk;
    logic rst_n;
    logic [8-1:0] data_out;
    logic rx_done;
    logic rx_error;
    bit baud;
    uart_rcv_top DUT(clk, rst_n, data_in, data_out, rx_error, rx_done);

    initial begin
        rst_n = 0;   // first 100 us board is in reset state
        data_in =1;
        #150us;
        rst_n = 1;
        #8680ns;
        data_in= 0;
        #8680ns;
        data_in = 1;
        #8680ns;
        data_in = 0;
        #8680ns;
        data_in = 0;
        #8680ns;
        data_in = 1;
        #8680ns;
        data_in = 1;
        #8680ns;
        data_in = 1;
        #8680ns;
        data_in = 0;
        #8680ns;
        data_in = 1;
        #8680ns;
        data_in = 1;
        #8680ns;
        data_in = 1;
        #8680ns;
        data_in = 1;
        #50us;
        data_in = 0;
        #8680ns;
        data_in = 1;
        #8680ns;
        data_in = 0;
        #500us;
        
        $finish;
    end

    initial begin             // To generate clock
        clk = 0;              // initial value for clock is '0'
        forever begin           // endless loop SV
            clk = ~clk;     // assign itself with invert of previous value
            #5ns;                 
        end
    end
    
endmodule