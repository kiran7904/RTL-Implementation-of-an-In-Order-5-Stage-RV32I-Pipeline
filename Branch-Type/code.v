// ============================================================
// RV32I 5-STAGE IN-ORDER PIPELINE
// BEQ
//
// Example:
//     BEQ x1, x2, 16
//
// Branch resolved in EX.
//
// IF -> ID -> EX -> MEM -> WB
// ============================================================


// ============================================================
// 1. IF STAGE
// ============================================================

module if_stage (
    input  logic        clk,
    input  logic        rst,

    input  logic        branch_taken,
    input  logic [31:0] branch_target,

    output logic [31:0] pc,
    output logic [31:0] instruction
);

    logic [31:0] instr_mem [0:255];

    initial begin
        $readmemh("program.hex", instr_mem);
    end

    always_ff @(posedge clk or posedge rst) begin

        if (rst)
            pc <= 32'd0;

        else if (branch_taken)
            pc <= branch_target;

        else
            pc <= pc + 32'd4;

    end

    assign instruction = instr_mem[pc[9:2]];

endmodule


// ============================================================
// 2. IF / ID PIPELINE REGISTER
// ============================================================

module if_id_reg (
    input  logic        clk,
    input  logic        rst,

    input  logic        flush,

    input  logic [31:0] pc_in,
    input  logic [31:0] instr_in,

    output logic [31:0] pc_out,
    output logic [31:0] instr_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            pc_out    <= 32'd0;
            instr_out <= 32'd0;

        end

        else if (flush) begin

            pc_out    <= 32'd0;
            instr_out <= 32'd0;

        end

        else begin

            pc_out    <= pc_in;
            instr_out <= instr_in;

        end

    end

endmodule


// ============================================================
// 3. REGISTER FILE
// ============================================================

module register_file (
    input  logic        clk,

    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,

    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,

    input  logic        reg_write,
    input  logic [4:0]  rd,
    input  logic [31:0] write_data
);

    logic [31:0] regs [0:31];

    assign rs1_data = (rs1 == 5'd0) ? 32'd0 : regs[rs1];

    assign rs2_data = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

    always_ff @(posedge clk) begin

        if (reg_write && rd != 5'd0)
            regs[rd] <= write_data;

    end

endmodule


// ============================================================
// 4. ID STAGE
// ============================================================

module id_stage (
    input  logic [31:0] instr,

    output logic [4:0] rs1,
    output logic [4:0] rs2,

    output logic [31:0] immediate,

    output logic        branch,
    output logic        reg_write,

    output logic [2:0]  branch_type
);

    // --------------------------------------------------------
    // Register fields
    // --------------------------------------------------------

    assign rs1 = instr[19:15];

    assign rs2 = instr[24:20];


    // --------------------------------------------------------
    // BEQ immediate
    //
    // B-type immediate:
    //
    // imm[12]   = instr[31]
    // imm[11]   = instr[7]
    // imm[10:5] = instr[30:25]
    // imm[4:1]  = instr[11:8]
    // imm[0]    = 0
    // --------------------------------------------------------

    assign immediate = {
        {19{instr[31]}},
        instr[31],
        instr[7],
        instr[30:25],
        instr[11:8],
        1'b0
    };


    // --------------------------------------------------------
    // Control
    // --------------------------------------------------------

    always_comb begin

        branch      = 1'b0;
        reg_write   = 1'b0;
        branch_type = 3'b000;

        // BEQ opcode = 1100011
        if (instr[6:0] == 7'b1100011) begin

            // funct3 = 000 for BEQ
            if (instr[14:12] == 3'b000) begin

                branch      = 1'b1;
                branch_type = 3'b000;

            end

        end

    end

endmodule


// ============================================================
// 5. ID / EX PIPELINE REGISTER
// ============================================================

module id_ex_reg (
    input  logic        clk,
    input  logic        rst,

    input  logic        flush,

    input  logic [31:0] pc_in,

    input  logic [31:0] rs1_data_in,
    input  logic [31:0] rs2_data_in,

    input  logic [31:0] immediate_in,

    input  logic [4:0]  rs1_in,
    input  logic [4:0]  rs2_in,

    input  logic        branch_in,
    input  logic        reg_write_in,

    output logic [31:0] pc_out,

    output logic [31:0] rs1_data_out,
    output logic [31:0] rs2_data_out,

    output logic [31:0] immediate_out,

    output logic [4:0] rs1_out,
    output logic [4:0] rs2_out,

    output logic        branch_out,
    output logic        reg_write_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            pc_out <= 32'd0;

            rs1_data_out <= 32'd0;
            rs2_data_out <= 32'd0;

            immediate_out <= 32'd0;

            rs1_out <= 5'd0;
            rs2_out <= 5'd0;

            branch_out    <= 1'b0;
            reg_write_out <= 1'b0;

        end

        else if (flush) begin

            branch_out    <= 1'b0;
            reg_write_out <= 1'b0;

        end

        else begin

            pc_out <= pc_in;

            rs1_data_out <= rs1_data_in;
            rs2_data_out <= rs2_data_in;

            immediate_out <= immediate_in;

            rs1_out <= rs1_in;
            rs2_out <= rs2_in;

            branch_out    <= branch_in;
            reg_write_out <= reg_write_in;

        end

    end

endmodule


// ============================================================
// 6. EX STAGE
// ============================================================

module ex_stage (
    input  logic [31:0] pc,

    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,

    input  logic [31:0] immediate,

    input  logic        branch,

    output logic        branch_taken,
    output logic [31:0] branch_target
);

    // --------------------------------------------------------
    // Branch target
    // --------------------------------------------------------

    assign branch_target = pc + immediate;


    // --------------------------------------------------------
    // BEQ comparison
    // --------------------------------------------------------

    always_comb begin

        branch_taken = 1'b0;

        if (branch) begin

            if (rs1_data == rs2_data)
                branch_taken = 1'b1;

        end

    end

endmodule


// ============================================================
// 7. EX / MEM PIPELINE REGISTER
// ============================================================

module ex_mem_reg (
    input logic clk,
    input logic rst,

    input logic reg_write_in,

    output logic reg_write_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst)
            reg_write_out <= 1'b0;

        else
            reg_write_out <= reg_write_in;

    end

endmodule


// ============================================================
// 8. MEM STAGE
// ============================================================

module mem_stage (
    output logic [31:0] result
);

    // BEQ does not access data memory.
    assign result = 32'd0;

endmodule


// ============================================================
// 9. MEM / WB PIPELINE REGISTER
// ============================================================

module mem_wb_reg (
    input logic clk,
    input logic rst,

    input logic reg_write_in,

    output logic reg_write_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst)
            reg_write_out <= 1'b0;

        else
            reg_write_out <= reg_write_in;

    end

endmodule


// ============================================================
// 10. TOP MODULE
// ============================================================

module rv32_beq_pipeline (
    input logic clk,
    input logic rst
);

    // --------------------------------------------------------
    // IF
    // --------------------------------------------------------

    logic [31:0] pc_if;
    logic [31:0] instr_if;


    // --------------------------------------------------------
    // Branch control
    // --------------------------------------------------------

    logic        branch_taken;
    logic [31:0] branch_target;


    // --------------------------------------------------------
    // IF / ID
    // --------------------------------------------------------

    logic [31:0] pc_id;
    logic [31:0] instr_id;


    // --------------------------------------------------------
    // ID
    // --------------------------------------------------------

    logic [4:0] rs1_id;
    logic [4:0] rs2_id;

    logic [31:0] immediate_id;

    logic branch_id;
    logic reg_write_id;


    // --------------------------------------------------------
    // Register file
    // --------------------------------------------------------

    logic [31:0] rs1_data_id;
    logic [31:0] rs2_data_id;


    // --------------------------------------------------------
    // ID / EX
    // --------------------------------------------------------

    logic [31:0] pc_ex;

    logic [31:0] rs1_data_ex;
    logic [31:0] rs2_data_ex;

    logic [31:0] immediate_ex;

    logic [4:0] rs1_ex;
    logic [4:0] rs2_ex;

    logic branch_ex;
    logic reg_write_ex;


    // --------------------------------------------------------
    // EX / MEM
    // --------------------------------------------------------

    logic reg_write_mem;


    // --------------------------------------------------------
    // MEM / WB
    // --------------------------------------------------------

    logic reg_write_wb;


    // ========================================================
    // IF
    // ========================================================

    if_stage IF (
        .clk           (clk),
        .rst           (rst),

        .branch_taken  (branch_taken),
        .branch_target (branch_target),

        .pc            (pc_if),
        .instruction   (instr_if)
    );


    // ========================================================
    // IF -> ID
    //
    // If branch is taken, flush the wrong-path instruction.
    // ========================================================

    if_id_reg IF_ID (
        .clk       (clk),
        .rst       (rst),

        .flush     (branch_taken),

        .pc_in     (pc_if),
        .instr_in  (instr_if),

        .pc_out    (pc_id),
        .instr_out (instr_id)
    );


    // ========================================================
    // REGISTER FILE
    // ========================================================

    register_file REGFILE (
        .clk        (clk),

        .rs1        (rs1_id),
        .rs2        (rs2_id),

        .rs1_data   (rs1_data_id),
        .rs2_data   (rs2_data_id),

        // BEQ does not write a register.
        .reg_write  (1'b0),
        .rd         (5'd0),
        .write_data (32'd0)
    );


    // ========================================================
    // ID
    // ========================================================

    id_stage ID (
        .instr        (instr_id),

        .rs1          (rs1_id),
        .rs2          (rs2_id),

        .immediate    (immediate_id),

        .branch       (branch_id),
        .reg_write    (reg_write_id),

        .branch_type  ()
    );


    // ========================================================
    // ID -> EX
    // ========================================================

    id_ex_reg ID_EX (
        .clk            (clk),
        .rst            (rst),

        .flush          (branch_taken),

        .pc_in          (pc_id),

        .rs1_data_in    (rs1_data_id),
        .rs2_data_in    (rs2_data_id),

        .immediate_in   (immediate_id),

        .rs1_in         (rs1_id),
        .rs2_in         (rs2_id),

        .branch_in      (branch_id),
        .reg_write_in   (reg_write_id),

        .pc_out         (pc_ex),

        .rs1_data_out   (rs1_data_ex),
        .rs2_data_out   (rs2_data_ex),

        .immediate_out  (immediate_ex),

        .rs1_out        (rs1_ex),
        .rs2_out        (rs2_ex),

        .branch_out     (branch_ex),
        .reg_write_out  (reg_write_ex)
    );


    // ========================================================
    // EX
    // ========================================================

    ex_stage EX (
        .pc             (pc_ex),

        .rs1_data       (rs1_data_ex),
        .rs2_data       (rs2_data_ex),

        .immediate      (immediate_ex),

        .branch         (branch_ex),

        .branch_taken   (branch_taken),
        .branch_target  (branch_target)
    );


    // ========================================================
    // EX -> MEM
    // ========================================================

    ex_mem_reg EX_MEM (
        .clk            (clk),
        .rst            (rst),

        .reg_write_in   (reg_write_ex),

        .reg_write_out  (reg_write_mem)
    );


    // ========================================================
    // MEM
    // ========================================================

    mem_stage MEM (
        .result ()
    );


    // ========================================================
    // MEM -> WB
    // ========================================================

    mem_wb_reg MEM_WB (
        .clk            (clk),
        .rst            (rst),

        .reg_write_in   (reg_write_mem),

        .reg_write_out  (reg_write_wb)
    );

endmodule
