`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ayengec
// Engineer: ayengec
// 
// Create Date: 06/24/2021 05:16:36 PM
// Design Name: 
// Module Name: tb_spi_master_tr
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


module tb_spi_master_tr();
 logic       clk;
 logic       enable;
 logic[7:0]  w_data_to_mosi;
 logic[7:0]  r_data_from_miso;
 logic       data_ready;
 logic       cs;
 logic       sclk_out;
 logic       mosi;
 logic       miso;
 
 spi_master#(100000000, 1000000, 0, 0) m_spi_master(.*);
 
 event write_done_event;
 event write_start_event;
 
 logic[7:0]  mosi_data='h0;
 logic[7:0]  slave_response_data='h0;
 
 initial begin
    
    wait(write_start_event.triggered);
    for(int i=7; i>=0; i--) begin
        @(negedge(sclk_out)) ;
        miso = slave_response_data[i]; 
    end
    
    ->write_done_event;
    end
 ///////////////////////   
 initial begin
    enable = 0;
    #100us;
    
    w_data_to_mosi = 'hB4;
    enable = 1;
    @(negedge cs);
    
    @(posedge data_ready);
    w_data_to_mosi = 'h00;
    slave_response_data = 'hA5;
    ->write_start_event;
    wait(write_done_event.triggered);
    enable = 0;
    #50us;
    $finish;
 end 
 ////////////////////////
 initial begin
    clk = 0;
    forever begin
        clk = ~clk;
        #5ns;
    end
 end 
  
  
  
endmodule
