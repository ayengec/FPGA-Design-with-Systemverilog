`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ayengec
// Engineer: ayengec
// 
// Create Date: 06/22/2021 01:50:05 PM
// Design Name: 
// Module Name: i2c_master
// Project Name: i2c_master example
// Target Devices: 
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


module i2c_master#(int unsigned input_clk=100000000, int unsigned freq=400000)
    (
        input logic         clk,            //  system main clock
        input logic         rst_n,          //  system reset
        input logic         enable,         //  enable i2c master transfer sequence
        input logic[6:0]    slv_addr,       //  Slave address of i2c
        input logic         RnW,            //  Read=1 or Write=0
        input logic[7:0]    data_wr,        //  write data to slave
        output logic        busy,           //  bus busy, i2c is in use
        output logic[7:0]   rd_data,        //  read data from slave
        output logic        nAck,           //  either ack error or not
        inout  wire        sda,             //  Serial data output/ack_in I2C bus
        inout wire         scl              //  Serial clock output of bus

    );
    /////////// CLOCK DIVISION VARIABLES //////////
    int unsigned divider = (input_clk/freq)/4;  //how many system clock needs for one SCL period
    int unsigned clk_counter;
    int unsigned scl_counter;                 // they are generated in scl_clock_generator ff
    logic data_clk;                           // data clock for sda
    logic data_clk_prev;                      // previous data clock 
    logic scl_clk;                            // constant internal scl
    ////////////////////////////////////////////////////////////////////////////////////////////
    logic scl_enable=0;                       // enables internal scl to output scl
    logic sda_int=1;                          // internal sda
    logic sda_enable_n;                       // enables internal sda to output
    int unsigned bit_cnt=7;                   // bit counter
    ////////////////////////////////////////////////////////////////////////////////////////////
    logic[7:0] addr_rw;                       // 7-bit address + RnW
    logic[7:0] data_tx;                       // Write data to be transmitted
    logic[7:0] data_rx;                       // Read data from slave
    ////////////////////////////////////////////////////////////////////////////////////////////
    logic stretch = 0;
    
    typedef enum logic[3:0] {                   // State machine cases
        READY,
        START,
        COMMAND,
        SLV_ACK1,
        WRITE,
        READ,
        SLV_ACK2,
        MSTR_ACK,
        STOP
    } state_t;

    state_t state;
    always_ff @(posedge(clk) or negedge(rst_n)) begin

        if(!rst_n) begin
            clk_counter     <= 0;
            stretch <= 0;
        end
        else begin
            data_clk_prev <= data_clk;
            if (clk_counter == (divider*4-1)) begin     // end of timing cycle
                clk_counter <= 0;                       // reset timer
            end
            else if (stretch == 0) begin                // clock stretching if slave not detected
                clk_counter     <= clk_counter + 1;
            end
        
            unique case(clk_counter) inside
                [0:divider-1]:begin                     // First 1/4 cycle of clocking
                    scl_clk  <= 0;                      
                    data_clk <= 0;
                end 

                [divider:divider*2-1]:begin             // Second 1/4 cycle of clocking
                    scl_clk  <= 0;
                    data_clk <= 1;
                end 

                [divider*2:divider*3-1]:begin           // Third 1/4 cycle of clocking
                    scl_clk  <= 1;                      // release scl
                    if(scl==0) begin
                        stretch <= 1;
                    end
                    else begin                          
                        stretch <= 0; 
                    end
                    data_clk <= 1;
                   
                end 
                
                default:begin                           // last 1/4 cycle of clocking
                    scl_clk  <= 1;
                    data_clk <= 0;
                end 
            endcase
        end
    end
        

    always_ff @(posedge(clk) or negedge(rst_n)) begin: data_transaction_machine
        if(!rst_n) begin
            state <= READY;             // reset asserted
            busy <= 0;                  // Clear busy flag
            scl_enable <= 0;            // Sets SCL to HIGH
            sda_int <= 1;               // sets SDA to HIGH
            nAck <= 0;                  // clear nAck flag
            bit_cnt <= 7;               // restarts bit counter
            rd_data <= 'h0;             // read data port clear
        end
        else if (clk) begin
            if (data_clk==1 & data_clk_prev==0) begin           // data clocking rising edge
                unique case(state) 

                    READY:begin                                       
                        if (enable) begin
                            busy    <= 1;
                            addr_rw <= {slv_addr, RnW};         // concatenation slvaddr+RnW
                            data_tx <= data_wr;                 // store requested data to write
                            state   <= START; 
                        end
                        else begin                              // if it isnt enabled, wait IDLE
                            busy  <= 0;
                            state <= READY;
                        end
                    end

                    START:begin                                 // Write first MSB bit to sda line
                        busy <= 1;
                        sda_int <= addr_rw[bit_cnt];
                        state   <= COMMAND;                     // Go to COMMAND state to write remaining bits
                    end

                    COMMAND:begin                               // Write slave address + RnW and goto wait slave ack
                        if (bit_cnt == 0) begin
                            sda_int <= 1;
                            bit_cnt <= 7;
                            state   <= SLV_ACK1;
                        end
                        else begin
                            bit_cnt <= bit_cnt -1;
                            sda_int <= addr_rw[bit_cnt-1];
                            state   <= COMMAND;
                        end
                    end

                    SLV_ACK1:begin
                        if (addr_rw[0] == 0) begin              // If WRITE COMMAND
                            sda_int <= data_tx[bit_cnt];        // Write first bit of data
                            state   <= WRITE;                   // Go to Write state
                        end
                        else begin
                            sda_int <= 1;                       // If it is not WRITE COMMAND, release SDA
                            state   <= READ;                    // and go to RD state
                        end
                    end

                    WRITE:begin                                 // Write data state
                        busy <= 1;
                        if (bit_cnt == 0) begin
                            sda_int <= 1;
                            bit_cnt <= 7;
                            state   <= SLV_ACK2;
                        end
                        else begin
                            bit_cnt <= bit_cnt -1;
                            sda_int <= data_tx[bit_cnt-1];      // write all 8 bit datas to sda line
                            state   <= WRITE;
                        end
                    end

                    READ:begin                                 // if request type is READ
                        busy <= 1;
                        if (bit_cnt == 0) begin
                            if (enable & (addr_rw == {slv_addr , RnW} )) begin
                                sda_int <= 0;
                            end
                            else begin
                                sda_int <= 1;
                            end
                            bit_cnt <= 7;
                            rd_data <= data_rx;
                            state   <= MSTR_ACK;
                        end
                        else begin
                            bit_cnt <= bit_cnt -1;
                            state   <= READ;
                        end
                    end

                    SLV_ACK2:begin                              // ack2= after address written process
                        if (enable) begin                       // ack of write data process
                            busy <= 0;
                            addr_rw <= {slv_addr, RnW};
                            data_tx <= data_wr;

                            if (addr_rw == {slv_addr, RnW}) begin
                                sda_int <= data_wr[bit_cnt];
                                state <= WRITE;
                            end
                            else begin
                                state <= START;
                            end
                        end
                        else begin
                            state <= STOP;
                        end
                        
                    end

                    MSTR_ACK:begin                                  // if reads data from slave, master must give ack to slave
                        if (enable == 1) begin
                            busy <= 0;
                            addr_rw <= {slv_addr, RnW};
                            data_tx <= data_wr;

                            if (addr_rw == {slv_addr , RnW}) begin
                                sda_int <= 1;
                                state <= READ;
                            end
                            else begin
                                state <= START;
                            end
                        end
                        else begin
                            state <= STOP;
                        end

                    end

                    STOP:begin                              // generate stop condition
                        busy  <= 0;
                        state <= READY;
                    end

                endcase
            end            

            else if (data_clk==0 & data_clk_prev==1) begin      // in every data clock falling edge  
                case(state)                                     // This machine checks protocol checks
                    START:begin                                 
                        if(!scl_enable) begin
                            scl_enable <= 1;
                            nAck <= 0;
                        end
                    end

                    SLV_ACK1:begin                              // if slave doesnt give ack, Raise nAck flag
                        if (!(sda===0) | nAck) begin
                            nAck <= 1;
                        end
                    end

                    READ:begin
                        data_rx[bit_cnt] <= sda;
                    end

                    SLV_ACK2:begin
                        if (!(sda===0) | nAck) begin
                            nAck <= 1;
                        end
                    end

                    STOP:begin
                        scl_enable <= 0;
                    end

                endcase
                
            end
        end

    end: data_transaction_machine

    always_comb begin                   
        unique case(state)
            START:begin                             // generating start condition
                sda_enable_n <= data_clk_prev;
            end
            STOP:begin                              // generating stop condition
                sda_enable_n <= ~data_clk_prev;
            end
            default: sda_enable_n <= sda_int;

        endcase
    end
    // because of the systemverilog's rule: inout ports cannot be assigned directly
    // if scl_enable and not(scl_clk) -->> main scl go to LOW, others Z
    assign scl = (scl_enable & !scl_clk) ? '0 : 'Z;
    // if sda_enable_n is not LOW -->> main sda go to LOW, others Z 
    assign sda = !sda_enable_n ? '0 : 'Z;

endmodule
