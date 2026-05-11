module FA_1B(a,b,cin,cout,s);
	//all inputs and outputs are 1-bit
	input a, b, cin; 
	output reg  cout, s; 

	always @ (a or b or cin) begin 
			{cout, s} = a + b + cin; 
	end

endmodule