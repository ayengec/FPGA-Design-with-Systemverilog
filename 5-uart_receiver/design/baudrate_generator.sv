`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  ayengec
// Engineer: ayengec
// 
// Create Date: 12.05.2021 14:03:26
// Design Name: baudrate_generator.sv
// Module Name: baudrate_generator
// Project Name: uart
// Target Devices: Artix-7
// Tool Versions: 2020.1
// Description: To general use, baudrate generator block is designed. We can select a clock 
//              whichever generated clock for transmitter or receiver
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module baudrate_generator #(parameter BAUDRATE=9600)   // default baudrate is set to 9600
(
    input logic  clk,               // system clock
    input logic  rst_n,             // system reset_en
    output logic tx_clk,            // transmitter clock is equal to BAUDRATE
    output logic rx_sampling_clk    // receiver clock is equal to double times BAUDRATE
);

    bit [31:0]  counter_rx;
    
    always_ff @(posedge(rx_sampling_clk) or negedge(rst_n)) begin // generation a clock about BAUDRATE for transmitter usage  

        if(!rst_n) begin
            tx_clk  <= 0;           
        end
        else begin
            tx_clk <= ~tx_clk;      // Invert tx_clk on every positive edge of rx_sampling_clk
                                    // so tx clk = rx_sampling_clk/2
        end
    end

    always_ff @( posedge(clk) or negedge(rst_n)) begin   // Nyquist Frequency must be minimum 2*BAUDRATE
                                                         // We need to sample every bit while receiving
        if(!rst_n) begin
            counter_rx <= 0;
            rx_sampling_clk     <= 0;
        end
        else if (counter_rx == (100000000/(4*BAUDRATE))) begin      
            /* 
                100 MHz clock embedded on BASYS-3 board
                We need rx_clock being min. double times of BAUDRATE.
                Each edge (rising or falling) is a half period for %50 duty cycle signals.
            */
            counter_rx <= 0;                                        
            rx_sampling_clk     <= ~rx_sampling_clk;
        end
        else begin
            counter_rx <= counter_rx + 32'b1;
        end
    end

endmodule: baudrate_generator