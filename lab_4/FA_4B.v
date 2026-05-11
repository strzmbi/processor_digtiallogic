module FA_4B(a,b,cin,cout,s);
	//some inputs and outputs are 1-bit, some are 4-bit

	input[3:0] a, b; 
	input cin; 

	wire[3:0] c; 
	
	output  cout; 
	output[3:0] s; 

	FA_1B first(.a(a[0]), .b(b[0]), .cin(cin), .cout(c[0]), .s(s[0]));

	genvar i; 
	generate
		for (i = 1; i < 4; i = i + 1) begin
			FA_1B fa_1b(.a(a[i]), .b(b[i]), .cin(c[i-1]), .cout(c[i]), .s(s[i]));
		end
	endgenerate

	assign cout = c[3]; 
endmodule