module ex_stage (
    input  logic [31:0] rs1_ex,
    input  logic [31:0] rs2_ex,
    output logic [31:0] alu_out
);
    assign alu_out = rs1_ex + rs2_ex;
endmodule
