module top(CLOCK_50, SW, KEY, HEX0, LEDR);
    input CLOCK_50;
    input [9:0] SW;
    input [3:0] KEY;
    output [6:0] HEX0;
    output [9:0] LEDR;
    
    wire [3:0] seconds;
    wire grant;


    fsm fsm ( .CLOCK_50(CLOCK_50), .KEY(KEY), SW(SW), .HEX0(HEX0), .LEDR(LEDR) );
    
    
    if (grant) begin
        assign LEDR = 10'b1111111111; 
    end else begin
        assign LEDR = 10'b0;
    end

endmodule
