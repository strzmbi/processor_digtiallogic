`timescale 1ns / 1ps
module L4P3_TB;

	reg [1:0] count;
	//Add inputs/outputs
	reg[3:0] a, b; 
	wire cout; 
	wire[3:0] s;
	
	//instantiate and connect fourBit_FA
	FA_4B fa_4b(.a(a), .b(b), .cin(1'b0), .cout(cout), .s(s));
 	
	initial begin 
		$dumpfile("function.vcd");
		$dumpvars(0, L4P3_TB);
		count = 2'b00;
		#1000

		$finish;
	end
	
	always begin
		#50
		count=count+2'b01;
	end

	assign c = 1'b0; 
	
	always @(count) begin
		case (count)
		 2'b00 : begin a = 4'b0000; b = 4'b0000; end  // expect s=0000, cout=0
        2'b01 : begin a = 4'b0001; b = 4'b0010; end  // expect s=0011, cout=0
        2'b10 : begin a = 4'b0111; b = 4'b1000; end  // expect s=1111, cout=0
        2'b11 : begin a = 4'b1111; b = 4'b0001; end  // expect s=1111, cout=0
		default : begin a = 4'b0000; b = 4'b0001; end
	endcase
	end
	
endmodule

/*
	cd usyd/26s1/elec2602/lab/4/p3
	iverilog -o out.vvp FA_1B.v FA_4B.v L4P3_TB.vb


*/