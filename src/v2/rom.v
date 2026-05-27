module rom(
    input  [4:0]  address,
    output [15:0] instruction
);
    reg [15:0] mem [0:31];

    initial begin
        $readmemh("program.hex", mem); 
    end

    assign instruction = mem[address];
endmodule