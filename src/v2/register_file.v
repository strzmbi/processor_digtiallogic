module register_file(
    input  [15:0] d,
    input         clk, rst,

    /* controlled by cu*/
    input         write_en,     //  enable
    input  [4:0]  read_addr,    // from register_tri

    /* written by / read from bus */
    input  [4:0]  write_addr,   // from register_en
    output [15:0] Q
);
    reg [15:0] regs [0:15];
    integer j;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (j = 0; j < 16; j = j + 1)
                regs[j] <= 16'd0;
        end else if (write_en) begin
            regs[write_addr] <= d;
        end
    end

    assign Q = regs[read_addr]; 
endmodule