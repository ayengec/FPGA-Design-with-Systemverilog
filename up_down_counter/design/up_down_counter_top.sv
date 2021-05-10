`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.05.2021 17:33:33
// Design Name: up_down_counter_top
// Module Name: up_down_counter_top.sv
// Project Name: up_down_counter_top
// Target Devices: Artix-7 BASYS-3 Board
// Tool Versions: 2020.1
// Description: It shows that how to divide clock, use variables
// 
// Dependencies: BASYS-3
// 
// Revision: 1
// Revision 0.01 - File Created
// Additional Comments: You can change your generated clock
// 
//////////////////////////////////////////////////////////////////////////////////

module up_down_counter_top(
    input  logic clk,                                               
    input  logic rst_n,
    input  logic dir,                   // direction of counter
    output logic [7:0] out_led
    );
    
    bit [31:0] counter;	                // counter for slow clock
	bit clk2;                           // slow clock to see real leds on board
	
always_ff @(posedge(clk) or negedge(rst_n)) begin   
    // generates clk2 as every 10 million clock positive after 10 M negative
    // 10M(+) x 10ns (board's clock) = 100 ms positive cycle similarly negative
    // total period of clk2 is 200ms so 5 Hz
	if(!rst_n) begin
		counter <= 0;
		clk2 <= 0;
	end
	else if (counter == 10000000) begin  // We can change this magic number how many hertz we want
		counter <= 0;
		clk2 = ~clk2;
	end
	else
			counter <= counter + 32'b1;
end
    
always_ff @(posedge(clk2) or negedge(rst_n)) begin // this process works every clk2's (our generated 5Hz) 
                                                   // signal positive
    if(!rst_n)
        out_led = 8'h00;
    else if(dir)
        out_led <= out_led+1;    // it shifts our leds incrementally if direction is 1
    else if (!dir)
        out_led <= out_led-1;    // it decreases our leds from previous number
end
    
endmodule
