`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ayengec
// Engineer: ayengec
// 
// Create Date: 13.05.2021 00:46:58
// Design Name: uart_transmitter.sv
// Module Name: uart_transmitter
// Project Name: uart_transmitter
// Target Devices: Artix-7
// Tool Versions: 2020.1
// Description: UART transmitter block is designed as parameterized.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_transmitter#(parameter DATA_WIDTH_NUMBER=8, STOP_BITS_NUMBER=2)
(
    input logic rst_n,
    input logic tx_clk,
    input logic tx_start,
    input logic [DATA_WIDTH_NUMBER-1:0] data_in,
    output logic tx_dout,
    output logic tx_done 
);

    typedef enum logic [1:0] // 2 bits are enough for 4-state
    {
            IDLE,
            START,
            DATA,
            STOP
    } state_t;

    state_t state;
    
    shortint unsigned data_cnt;  // to check how many data_in bits remaining
    shortint unsigned stop_cnt;  // to check how many stop bits must be inserted

    always_ff @( posedge(tx_clk) or negedge(rst_n) ) begin
        if (!rst_n) begin
            state <= IDLE;      // FSM waiting in IDLE state until tx_start triggered
            tx_done <= 1'b0;
            tx_dout <= 1'b1;    // tx_dout line must be high if unused
        end
        else begin
            unique case (state)
    
                IDLE:begin
                tx_done <= 1'b0;
                    if (tx_start) begin         
                        state <= START;
                        tx_dout <= 1'b0;    // if FSM triggered, first start bit inserted as '0' throughout 1 baud clock
                        data_cnt <= 1;      // data_cnt set to 1 because first index of data_in inserted in START state
                    end
                    else begin
                        tx_dout <= 1'b1;    // if FSM doesn't triggered, tx_dout must be high
                        stop_cnt <= 0;
                    end
                end
    
                START:begin
                    state   <= DATA;        // after the START state, FSM automatically passes to DATA state
                    tx_dout <= data_in[0];  // first data bit will be insterted to tx_dout in 
                                            // same baud clock at the beginning of the DATA state throughout 1 baud clock
                end
    
                DATA:begin
    
                    if (data_cnt == DATA_WIDTH_NUMBER) begin 
                        state <= STOP;
                        tx_dout  <= 1'b1;
                    end
                    else begin
                        tx_dout  <= data_in[data_cnt]; // data_in[0] was inserted previous state. 
                                                       // In this state, remainings will be put sequentially.
                        data_cnt <= data_cnt+1;
                    end
                end
    
                STOP:begin
                    if (stop_cnt == STOP_BITS_NUMBER-1) begin
                        tx_done <= 1'b1;
                        state <= IDLE;
                    end
                    else begin
                        tx_dout  <= 1'b1;           // stop bits are added as many as they are set
                        stop_cnt <= stop_cnt+1;
                        data_cnt <= 1;
                    end
                end            
            endcase
        end        
    end
endmodule
