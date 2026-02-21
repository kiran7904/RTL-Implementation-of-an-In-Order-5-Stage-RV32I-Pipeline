module id_stage (
    input  logic clk,
    input  logic rst,
    input  logic [31:0] instr_id,
    input  logic reg_write_wb,
    input  logic [4:0] rd_wb,
    input  logic [31:0] wb_data,
    output logic [31:0] rs1_val,
    output logic [31:0] rs2_val,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd
);
    logic [31:0] regfile [0:31];

    assign rs1 = instr_id[19:15];
    assign rs2 = instr_id[24:20];
    assign rd  = instr_id[11:7];

    always_ff @(posedge clk) begin
        if (reg_write_wb && rd_wb != 0)
            regfile[rd_wb] <= wb_data;
    end

    assign rs1_val = (rs1 != 0) ? regfile[rs1] : 0;
    assign rs2_val = (rs2 != 0) ? regfile[rs2] : 0;
endmodule
