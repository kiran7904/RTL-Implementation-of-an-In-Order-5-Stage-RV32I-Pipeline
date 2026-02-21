module rv32_pipeline_cpu (
    input  logic clk,
    input  logic rst
);
    logic [31:0] pc_if, instr_if;

    logic [31:0] pc_id, instr_id;
    logic [31:0] rs1_val, rs2_val;
    logic [4:0]  rs1, rs2, rd;

    logic [31:0] alu_out_ex, rs2_ex;
    logic [4:0]  rd_ex;
    logic        mem_read_ex, mem_write_ex, reg_write_ex;

    logic [31:0] mem_out_mem;
    logic [4:0]  rd_mem;
    logic        reg_write_mem;

    logic [31:0] wb_data;
    logic [4:0]  rd_wb;
    logic        reg_write_wb;

    logic stall;

    if_stage IF (.*);
    if_id_reg IF_ID (.*);
    id_stage ID (.*);
    id_ex_reg ID_EX (.*);
    ex_stage EX (.*);
    ex_mem_reg EX_MEM (.*);
    mem_stage MEM (.*);
    mem_wb_reg MEM_WB (.*);
    wb_stage WB (.*);
    hazard_unit HZ (.*);

endmodule
