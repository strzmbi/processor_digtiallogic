module sreg(
    input  [2:0]  difference,
    input         clk, rst, write_e,
    output [2:0]  values
);
    reg [2:0] stored;

    always @(posedge clk or posedge rst) begin
        if (rst)
            stored <= 3'b000;
        else if (write_e)
            stored <= difference;
    end

    assign Q = stored;
endmodule