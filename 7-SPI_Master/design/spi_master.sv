`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ayengec
// Engineer: ayengec
// 
// Create Date: 06/24/2021 02:52:27 PM
// Design Name: spi_master_simulation
// Module Name: spi_master
// Project Name: 
// Target Devices: Artix A7
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


module spi_master#(int unsigned sys_clk_freq = 100000000, int unsigned sclk_freq = 1000000, logic cpol = 0, logic cpha = 0) 
(
    input   logic      clk,
    input   logic      enable,
    input   logic[7:0] w_data_to_mosi,
    output  logic[7:0] r_data_from_miso,
    output  logic       data_ready,
    output  logic       cs,
    output  logic       sclk_out,
    output  logic       mosi,
    input   logic       miso
);

    /////////////////////////////////////////////////////////////////////////////////
    const int edge_counter_lim_div2 = sys_clk_freq/(sclk_freq*2);
    /////////////////////////////////////////////////////////////////////////////////
    logic[7:0]   write_reg = 'h0;
    logic[7:0]   read_reg  = 'h0;
    /////////////////////////////////////////////////////////////////////////////////
    logic   sclk_en   = 0;
    logic   sclk      = 0;
    logic   sclk_prev = 0;
    logic   sclk_rise = 0;
    logic   sclk_fall = 0;

    logic[1:0]   pol_phase = {cpol, cpha};
    logic        mosi_en = 0;
    logic        miso_en = 0;
    logic        once    = 0;

    shortint unsigned  edge_cntr = 0;
    shortint unsigned  cntr;
    /////////////////////////////////////////////////////////////////////////////////

    //  Typedef: <type_name>
    //  --- Prototype ---
    //  typedef enum #() <type_name>
    //  ---
    typedef enum logic {                   // State machine cases
        S_IDLE,
        S_TRANSFER
    } state_t;

    state_t state = S_IDLE;
    ////// according to cpha and cpol, decide whether enable the mosi or miso//////

    always_ff @(pol_phase, sclk_fall, sclk_rise) begin : mosi_miso_enable
        unique case(pol_phase)

            2'b00 : begin
                mosi_en <= sclk_fall;
                miso_en <= sclk_rise;
            end

            2'b01 : begin
                mosi_en <= sclk_rise;
                miso_en <= sclk_fall;
            end
            
            2'b10 : begin
                mosi_en <= sclk_rise;
                miso_en <= sclk_fall;
            end
            
            2'b11 : begin
                mosi_en <= sclk_fall;
                miso_en <= sclk_rise;
            end
        endcase  
    end: mosi_miso_enable
    /////////////////////////////////////////////////////////////////////////////////
    //////////////// SCLK RISE OR FALL STATE MECHANISM //////////////////////////////
    always_ff @(sclk, sclk_prev) begin : rise_fall_detector
        if (sclk & !sclk_prev) begin
            sclk_rise <= 1;
        end
        else begin
            sclk_rise <= 0;
        end

        if (!sclk & sclk_prev) begin
            sclk_fall <= 1;
        end
        else begin
            sclk_fall <= 0;
        end 
    end: rise_fall_detector
    /////////////////////////////////////////////////////////////////////////////////    
    
    always_ff @(posedge(clk)) begin : main_fsm
        data_ready <= 0;
        sclk_prev  <= sclk;

        unique case (state)
            S_IDLE:begin
                cs          <= 1;
                mosi        <= 0;
                data_ready  <= 0;
                sclk_en     <= 0;
                cntr        <= 0;

                if(cpol == 0) begin
                    sclk_out <= 0;
                end
                else begin
                    sclk_out <= 1;
                end

                if(enable) begin
                    state     <= S_TRANSFER;
                    sclk_en   <= 1;
                    write_reg <= w_data_to_mosi;
                    mosi      <= w_data_to_mosi[7];
                    read_reg  <= 'h0;
                end
            end

            S_TRANSFER:begin
                cs  <= 0;
                mosi <= write_reg[7];

                if (cpha) begin: cpha_is_1

                
                    if(cntr==0) begin
                        
                        sclk_out <= sclk;
                    
                        if(miso_en) begin
                            read_reg[0]   <= miso;
                            read_reg[7:1] <= read_reg[6:0];
                            cntr          <= cntr + 1;
                            once          <= 1;
                        end
                    end
                    else if(cntr == 8) begin
                        if(once) begin
                            data_ready <= 1;
                            once       <= 0;
                        end
                        r_data_from_miso <= read_reg;

                        if(mosi_en) begin
                            if (enable) begin
                                write_reg <= w_data_to_mosi;
                                mosi      <= w_data_to_mosi[7];
                                sclk_out  <= sclk;
                                cntr      <= 0;
                            end
                            else begin
                                state <= S_IDLE;
                                cs    <= 1;
                            end
                        end
                    end

                    else if(cntr == 9) begin
                        if(miso_en) begin
                            state <= S_IDLE;
                            cs    <= 1;
                        end
                    end

                    else begin
                        sclk_out <= sclk;
                        if(miso_en)begin
                            read_reg[0]   <= miso;
                            read_reg[7:1] <= read_reg[6:0];
                            cntr          <= cntr + 1;
                        end
                        if(mosi_en)begin
                            mosi           <= write_reg[7];
                            write_reg[7:1] <= write_reg[6:0];
                        end
                    end

                end:cpha_is_1

                else begin: cpha_is_not_1
                
                    if(cntr==0) begin
                        
                        sclk_out <= sclk;
                    
                        if(miso_en) begin
                            read_reg[0]   <= miso;
                            read_reg[7:1] <= read_reg[6:0];
                            cntr          <= cntr + 1;
                            once          <= 1;
                        end
                    end
                    else if(cntr == 8) begin
                        if(once) begin
                            data_ready <= 1;
                            once       <= 0;
                        end
                        r_data_from_miso <= read_reg;
                        sclk_out         <= sclk;

                        if(mosi_en) begin
                            if (enable) begin
                                write_reg <= w_data_to_mosi;
                                mosi      <= w_data_to_mosi[7];
                                cntr      <= 0;
                            end
                            else begin
                                cntr <= cntr + 1;
                            end
                            if (miso_en) begin
                                state <= S_IDLE;
                                cs      <= 1;
                            end

                        end
                    end

                    else if(cntr == 9) begin
                        if(miso_en) begin
                            state <= S_IDLE;
                            cs    <= 1;
                        end
                    end

                    else begin
                        sclk_out <= sclk;
                        if(miso_en)begin
                            read_reg[0]   <= miso;
                            read_reg[7:1] <= read_reg[6:0];
                            cntr          <= cntr + 1;
                        end
                        if(mosi_en)begin
                            write_reg[7:1] <= write_reg[6:0];
                        end
                    end


                end: cpha_is_not_1
            end
        endcase


    end: main_fsm
    /////////////////// SCLK GENERATION MECHANISM //////////////////////////////
    always_ff @(posedge clk) begin: sclk_generator
        if (sclk_en) begin: is_sclk_enable
            if (edge_cntr == edge_counter_lim_div2-1) begin
                sclk      <= !sclk;
                edge_cntr <= 0;
            end
            else begin
                edge_cntr <= edge_cntr + 1;
            end
            
        end: is_sclk_enable

        else begin: sclk_is_not_enable
            edge_cntr <= 0;
            if(cpol == 0) begin
                sclk <= 0;
            end
            else begin
                sclk <= 1;
            end
        end: sclk_is_not_enable
        
    end: sclk_generator
    //////////////////////////////////////////////////////////////////////////////
endmodule
    
