module sreg(difference, clk, rst, write_e, Q, notQ);
    input[2:0] difference;
    input clk, rst, write_e;
    output[2:0] Q, notQ;
    wire[2:0] temp;

    reg [2:0] stored;

    always @(posedge clk or posedge rst) begin
        if (rst)        stored <= 3'b000;
        else if (write_e) stored <= difference;
    end

    assign Q    = stored;
    assign notQ = ~stored;
endmodule

// module sreg(difference, overflow, clk, rst, write_e, Q, notQ);
//     input[14:0] difference;
//     input overflow, clk, rst, write_e;
//     output[15:0] Q, notQ;
//     wire[15:0] temp;

//     gle e(.difference(difference), .overflow(overflow), .r(temp));
//     register r(.d(temp), .clk(clk), .rst(rst), .write_e(write_e), .Q(Q), .notQ(notQ));
// endmodule