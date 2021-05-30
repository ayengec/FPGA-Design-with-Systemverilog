`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ayengec
// Engineer: ayengec
// 
// Create Date: 30.05.2021 19:40:06
// Design Name: uart receiver top design file
// Module Name: uart_rcv_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: uart_receiver and baudrate_generator
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



`define DATA_WIDTH_NUMBER 8    // 8 bit data for each frame
`define STOP_BITS_NUMBER  2    // how many bits will be inserted '1' as stop bits
`define BAUDRATE          115200 

module uart_rcv_top(
    input logic clk,
    input logic rst_n,
    input logic data_in,   

    output logic [`DATA_WIDTH_NUMBER-1:0] data_out, 
    output logic rx_error,                  
    output logic rx_done                
    );
    
    logic rx_clk_reg;               // will be used to connect between baudrate generator and uart_receiver module
    logic tx_clk_reg;               // will be used to connect between baudrate generator and uart_receiver module
    baudrate_generator#(`BAUDRATE) U1_BG( 
                                .clk(clk), 
                                .rst_n(rst_n),         
                                .tx_clk(tx_clk_reg),        
                                .rx_sampling_clk(rx_clk_reg)
                                );

    uart_receiver#(`DATA_WIDTH_NUMBER, `STOP_BITS_NUMBER) U3_RX( 
                                .rst_n(rst_n),
                                .data_in(data_in),
                                .sample_clk(rx_clk_reg),
                                .data_out(data_out),
                                .rx_done(rx_done),
                                .rx_error(rx_error)
                                );

endmodule
