module ram (
   input [ADDR_WIDTH-1:0] address, // Address Input
   inout [DATA_WIDTH-1:0]  data,   // Data bi-directional
   input chip_sel,                       // Chip Select
   input write_en,                       // Write Enable/Read Enable
   input read_en                        // Output Enable
);         

/***************************************************************************
   INITAL STATEMENT
 -------------------------------------------------------------------------*/
parameter   DATA_WIDTH      = 16                ;
parameter   ADDR_WIDTH      = 4                 ;
parameter   RAM_DEPTH       = 1 << ADDR_WIDTH   ;
/*------------------------------------------------------------------------*/
reg     [DATA_WIDTH-1:0]        data_out            ;
reg     [DATA_WIDTH-1:0]        mem [0:RAM_DEPTH-1] ;

/***************************************************************************
   TRI-STATE BUFFER CONTROL
   output : When write_en = 0, read_en = 1, chip_sel = 1
 -------------------------------------------------------------------------*/
assign data     = (chip_sel && read_en && !write_en)     ?   data_out    :   16'bz; 

/***************************************************************************
   MEMORY WRITE BLOCK
   Write Operation : When write_en = 1, chip_sel = 1
 -------------------------------------------------------------------------*/
always @ (address or data or chip_sel or write_en)
begin : MEM_WRITE
   if ( chip_sel && write_en ) begin
       mem[address] = data;
   end
end

/***************************************************************************
   MEMORY READ BLOCK
   Read Operation : When write_en = 0, read_en = 1, chip_sel = 1
 -------------------------------------------------------------------------*/
always @ (address or chip_sel or write_en or read_en)
begin : MEM_READ
    if (chip_sel && !write_en && read_en)  begin
         data_out = mem[address];
    end
end

endmodule