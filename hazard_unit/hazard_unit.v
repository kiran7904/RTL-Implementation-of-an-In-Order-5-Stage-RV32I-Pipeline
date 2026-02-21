module hazard_unit (
    input  logic [4:0] rs1,
    input  logic [4:0] rs2,
    input  logic [4:0] rd_ex,
    output logic stall
);
    assign stall = (rd_ex != 0) && (rd_ex == rs1 || rd_ex == rs2);
endmodule
