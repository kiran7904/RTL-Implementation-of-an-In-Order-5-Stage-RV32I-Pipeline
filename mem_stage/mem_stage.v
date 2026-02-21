module mem_stage (
    input  logic [31:0] alu_out_mem,
    output logic [31:0] mem_out
);
    assign mem_out = alu_out_mem;
endmodule
