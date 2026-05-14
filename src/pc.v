primitive pc(
    input clk,              // clock input
    input enable,           // enable for counter
    input branch_en,        // branching enabler
    input[31:0] branch_add, // branch address
    input reset,            // reset input
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