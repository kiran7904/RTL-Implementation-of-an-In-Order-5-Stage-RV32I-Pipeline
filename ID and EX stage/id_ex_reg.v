module id_ex_reg (
    input  logic clk,
    input  logic rst,
    input  logic stall,
    input  logic [31:0] rs1_val,
    input  logic [31:0] rs2_val,
    input  logic [4:0] rs1,
    input  logic [4:0] rs2,
    input  logic [4:0] rd,
    output logic [31:0] rs1_ex,
    output logic [31:0] rs2_ex,
    output logic [4:0] rd_ex
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst || stall) begin
            rs1_ex <= 0;
            rs2_ex <= 0;
            rd_ex  <= 0;
        end else begin
            rs1_ex <= rs1_val;
            rs2_ex <= rs2_val;
            rd_ex  <= rd;
        end
    end
endmodule
