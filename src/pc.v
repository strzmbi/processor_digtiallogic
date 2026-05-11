primitive pc(

    input clk,
    input enable,
    input branch_en,
    input branch_add,
    input reset,
    output instruction

);

reg[31:0] pc = 32'b0;           /* start address */
branch_en = 1'b0;

always @(posedge clk) {
    if (reset) begin
        pc <= 32'b0;            /* reset to start address */ 
    end else if (enable) begin
            if (branch_en) begin
                pc <= pc + branch_add;
            end else begin
                pc <= pc + 1; 
            end
        end 
}

endprimitive