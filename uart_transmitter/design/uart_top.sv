`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2021 13:39:58
// Design Name: 
// Module Name: uart_top
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
`define DATA_WIDTH_NUMBER 8    // 8 bit data for each frame
`define STOP_BITS_NUMBER  2    // how many bits will be inserted '1' as stop bits
`define BAUDRATE          9600 // this is changed to 115200 baudrate in last logic analyzer snapshot 

module uart_top(
    input logic clk,
    input logic rst_n,
    input logic tx_start,         // tx_start triggers the FSM
    input logic [`DATA_WIDTH_NUMBER-1:0] data_in, // the data vector will be serialized
    output logic tx_dout,                   // serial data output
    output logic tx_done                    // to check whether trasmitting is done or not
    );

    logic tx_clk_reg;               // to connect from baudrate_generator's output tx_clk to uart_transmitter's tx_clk
    logic rx_clk_reg;               // will be used to connect between baudrate generator and uart_receiver module

    baudrate_generator#(`BAUDRATE) U1_BG( 
                                .clk(clk), 
                                .rst_n(rst_n),         
                                .tx_clk(tx_clk_reg),        
                                .rx_sampling_clk(rx_clk_reg)
                                );

    uart_transmitter#(`DATA_WIDTH_NUMBER, `STOP_BITS_NUMBER) U2_TX( 
                                .rst_n(rst_n),
                                .tx_clk(tx_clk_reg),
                                .tx_start(tx_start),
                                .data_in(data_in),
                                .tx_dout(tx_dout),
                                .tx_done(tx_done)
                                );

endmodule
