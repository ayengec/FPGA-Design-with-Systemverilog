`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/23/2021 10:33:40 AM
// Design Name: 
// Module Name: tb_i2c_master
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


module tb_i2c_master();
  event m_event;

  logic         clk;           
  logic         rst_n;         
  logic         enable;        
  logic[6:0]    slv_addr;      
  logic         RnW;           
  logic[7:0]    data_wr;       
  logic        busy;          
  logic[7:0]   rd_data;       
  logic        nAck;          
  wire        sda;           
  wire        scl;
  bit[8:0] m_wr_data;
  bit       wr_data_get;
  
  i2c_master#(100000000,400000) DUT(.clk(clk),
                                    .rst_n(rst_n),
                                    .enable(enable),
                                    .slv_addr(slv_addr),
                                    .RnW(RnW),
                                    .data_wr(data_wr),
                                    .busy(busy),
                                    .rd_data(rd_data),
                                    .nAck(nAck),
                                    .sda(sda),
                                    .scl(scl)
                                     );
      
    
      
  initial begin
    rst_n  = 0;
    enable = 0;
    wr_data_get = 0;
    slv_addr = 'h78;
    RnW= 0;
    data_wr = 'h56;
    #100ns;
    rst_n = 1;
    #60us;
    enable = 1;
    @(posedge busy);
    enable = 0;
    m_wr_data='h0;
    
    for(int i=8; i>=0; i--) begin
        @(negedge(scl)) ;
        if(sda ===0) begin
            m_wr_data[i] = 0; 
        end
        else begin
            m_wr_data[i] = 1;
        end       
    end
    if (m_wr_data[0]== '0) begin
        wr_data_get = 1;
        @(negedge scl);
        wr_data_get = 0;
    end 
    
    m_wr_data='h0;
    
    for(int i=7; i>=0; i--) begin
        @(negedge(scl)) ;
        if(sda ===0) begin
            m_wr_data[i] = 0; 
        end
        else begin
            m_wr_data[i] = 1;
        end       
    end
    if (m_wr_data[0]== '0) begin
        wr_data_get = 1;
        @(negedge scl);
        wr_data_get = 0;
    end

    $display(m_wr_data);
    #100us;
    $finish;
    
  end

    assign sda = (wr_data_get == 1) ? '0 :'Z ;
    
  initial begin
    clk = 0;
    forever begin
     clk = ~clk;
     #5ns;
    end
  end 
  
endmodule
