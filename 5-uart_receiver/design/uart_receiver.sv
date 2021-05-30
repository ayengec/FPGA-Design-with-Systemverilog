`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ayengec
// Engineer: ayengec
// 
// Create Date: 29.05.2021 18:58:55
// Design Name: uart_receiver
// Module Name: uart_receiver
// Project Name: UART RECEIVER DESIGN WITH SYSTEMVERILOG
// Target Devices: Artix-7
// Tool Versions: 2020.1
// Description: This module explains how uart receiver is designed.
// 
// Dependencies: This module needs to baudrate generator for implemented design or some clock 
// sources with minimum double clock according to transmitter clock
// 
// Revision:-
// Revision 0.01 - File Created
// Additional Comments:-
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_receiver#(parameter DATA_WIDTH_NUMBER=8, STOP_BITS_NUMBER=2)(
    input  logic data_in,           // serial data input
    input  logic sample_clk,        // sample clock is equal to half baud_clock
    input  logic rst_n,             // system reset

    output logic [DATA_WIDTH_NUMBER-1:0] data_out,  // how many data bit on a frame sending by transmitter
    output logic rx_done,           // only '1' when receiving process successfully
    output logic rx_error           // if stop bits are not high'1' as pre-defined number, this error is going to high '1'
    );

    // States of Receiving process
    typedef enum logic [1:0] {
        IDLE,
        DATA,
        STOP
    } state_t;

    state_t state;                  // state object is instantiated from state_type
    
    shortint unsigned idx = 0;          // index of data or stop bits
    shortint unsigned clk_counter = 0;  // we use half clock. To sync after start bit's middle

    always_ff @(posedge(sample_clk) or negedge(rst_n)) begin
        if (!rst_n) begin       // if system reset is low, all outputs are going to Z
            data_out <= 'hZ;
            rx_done  <= 1'bZ;
            rx_error <= 1'bZ;
            state    <= IDLE;
        end

        else begin
            unique case (state)
                IDLE:begin
                    rx_done <= 1'b0;     
                    // if serial data_in is coming LOW, it means that start bit is coming
                    // but to be sure, we need to know that this low state must be stable throughout one baud clock= 2*sample_clk
                    if (data_in == 0) begin         
                        if (clk_counter < 1) begin  
                            clk_counter <= clk_counter +1; // 2 sample_clk period data_in should be low
                        end
                        else begin
                            state <= DATA;  // after being sure start bit has come, state should be go to DATA state
                            clk_counter <= 0;  // counter is zeroized for next frames
                        end
                    end
                    else begin
                        state <= IDLE;      // If there is no fluctiation on data_in, state should be IDLE everytime
                    end                     
                end

                DATA:begin
                    
                    if (idx == DATA_WIDTH_NUMBER) begin      // if all data bits are completed, we need to check stop bits are true?
                        state <= STOP;
                        clk_counter <= 0;
                        idx <= 0; 
                    end
                    else begin
                        if (clk_counter < 1) begin
                                clk_counter <= clk_counter +1; // same logic: we need sample all data bits at double sample_clk time
                            end
                        else begin
                            data_out[idx]  <= data_in;  // actual data_in value serial to paralelized in this phase at every double sample_clk 
                            state <= DATA;              // continue this phase while all data bits are completed.
                            clk_counter <= 0;
                            idx <= idx+1;               // all data bits will be put with this index
                        end
                    end
                end

                STOP:begin
                    if (idx == STOP_BITS_NUMBER) begin      // check stop bits are valid or invalid
                        state <= IDLE;
                        rx_done <= 1;
                        idx <= 0; 
                    end
                    else begin
                        if (clk_counter < 1) begin              // same logic: each double sample_clk = 1 baud clk
                                clk_counter <= clk_counter +1;
                        end
                        else begin
                            if (data_in) begin
                                idx <= idx+1;                   // same index variable is used for how many stop 
                                                                // bits must be checked but only data_in = HIGH
                            end
                            else begin
                                rx_error <= 1'b1;               // if data_in isn't HIGH, there is no stop bits
                                                                // we need to raise error flag
                                state <= IDLE;
                            end
                        end
                    end
                end
            endcase
        end
    end
endmodule
