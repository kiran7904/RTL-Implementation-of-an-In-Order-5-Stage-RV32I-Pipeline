// ============================================================
// RV32I 5-STAGE IN-ORDER PIPELINE
// LOAD WORD (LW)
//
// IF -> ID -> EX -> MEM -> WB
//
// Example:
//     LW x5, 8(x1)
//
// Flow:
//     x1 + 8
//       |
//      EX
//       |
//   EX/MEM register
//       |
//   memory address
//       |
//      MEM
//       |
//   loaded data
//       |
//   MEM/WB register
//       |
//      WB
//       |
//      x5
// ============================================================


// ============================================================
// 1. IF STAGE
// ============================================================

module if_stage (
    input  logic        clk,
    input  logic        rst,

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
        else
            pc <= pc + 32'd4;
    end

    // PC is byte address.
    // Divide by 4 to get instruction index.
    assign instruction = instr_mem[pc[9:2]];

endmodule


// ============================================================
// 2. IF / ID PIPELINE REGISTER
// ============================================================

module if_id_reg (
    input  logic        clk,
    input  logic        rst,

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

    // Read ports
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,

    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,

    // Write port
    input  logic        reg_write,
    input  logic [4:0]  rd,
    input  logic [31:0] write_data
);

    logic [31:0] regs [0:31];

    // x0 is always zero

    assign rs1_data = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign rs2_data = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

    always_ff @(posedge clk) begin

        if (reg_write && (rd != 5'd0))
            regs[rd] <= write_data;

    end

endmodule


// ============================================================
// 4. ID STAGE
// ============================================================

module id_stage (
    input  logic [31:0] instr,

    output logic [4:0]  rs1,
    output logic [4:0]  rd,

    output logic [31:0] immediate,

    output logic        reg_write,
    output logic        mem_read,
    output logic        mem_write,
    output logic        alu_src,
    output logic        mem_to_reg
);

    // --------------------------------------------------------
    // Instruction fields
    // --------------------------------------------------------

    assign rs1 = instr[19:15];

    assign rd  = instr[11:7];


    // --------------------------------------------------------
    // I-type immediate
    //
    // LW immediate = instruction[31:20]
    // --------------------------------------------------------

    assign immediate = {{20{instr[31]}}, instr[31:20]};


    // --------------------------------------------------------
    // Control signals
    // --------------------------------------------------------

    always_comb begin

        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        alu_src    = 1'b0;
        mem_to_reg = 1'b0;

        // LW opcode = 0000011

        if (instr[6:0] == 7'b0000011) begin

            reg_write  = 1'b1;
            mem_read   = 1'b1;
            mem_write  = 1'b0;

            // ALU B input = immediate
            alu_src    = 1'b1;

            // WB gets memory data
            mem_to_reg = 1'b1;

        end

    end

endmodule


// ============================================================
// 5. ID / EX PIPELINE REGISTER
// ============================================================

module id_ex_reg (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] rs1_data_in,
    input  logic [31:0] immediate_in,

    input  logic [4:0]  rd_in,

    input  logic        reg_write_in,
    input  logic        mem_read_in,
    input  logic        mem_write_in,
    input  logic        alu_src_in,
    input  logic        mem_to_reg_in,

    output logic [31:0] rs1_data_out,
    output logic [31:0] immediate_out,

    output logic [4:0]  rd_out,

    output logic        reg_write_out,
    output logic        mem_read_out,
    output logic        mem_write_out,
    output logic        alu_src_out,
    output logic        mem_to_reg_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            rs1_data_out  <= 32'd0;
            immediate_out <= 32'd0;

            rd_out <= 5'd0;

            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            alu_src_out    <= 1'b0;
            mem_to_reg_out <= 1'b0;

        end

        else begin

            rs1_data_out  <= rs1_data_in;
            immediate_out <= immediate_in;

            rd_out <= rd_in;

            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            alu_src_out    <= alu_src_in;
            mem_to_reg_out <= mem_to_reg_in;

        end

    end

endmodule


// ============================================================
// 6. EX STAGE
// ============================================================

module ex_stage (
    input  logic [31:0] rs1_data,
    input  logic [31:0] immediate,

    input  logic        alu_src,

    output logic [31:0] alu_result
);

    always_comb begin

        if (alu_src)
            alu_result = rs1_data + immediate;

        else
            alu_result = rs1_data;

    end

endmodule


// ============================================================
// 7. EX / MEM PIPELINE REGISTER
//
// IMPORTANT:
// alu_result here is the EFFECTIVE MEMORY ADDRESS for LW.
// ============================================================

module ex_mem_reg (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] alu_result_in,
    input  logic [4:0]  rd_in,

    input  logic        reg_write_in,
    input  logic        mem_read_in,
    input  logic        mem_write_in,
    input  logic        mem_to_reg_in,

    output logic [31:0] alu_result_out,
    output logic [4:0]  rd_out,

    output logic        reg_write_out,
    output logic        mem_read_out,
    output logic        mem_write_out,
    output logic        mem_to_reg_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            alu_result_out <= 32'd0;
            rd_out         <= 5'd0;

            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;

        end

        else begin

            alu_result_out <= alu_result_in;
            rd_out         <= rd_in;

            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;

        end

    end

endmodule


// ============================================================
// 8. DATA MEMORY
//
// The address comes FROM EX through EX/MEM.
// ============================================================

module data_memory (
    input  logic        clk,

    input  logic        mem_read,
    input  logic        mem_write,

    input  logic [31:0] address,

    input  logic [31:0] write_data,

    output logic [31:0] read_data
);

    logic [31:0] memory [0:255];


    // --------------------------------------------------------
    // Read
    // --------------------------------------------------------

    always_comb begin

        if (mem_read)
            read_data = memory[address[9:2]];

        else
            read_data = 32'd0;

    end


    // --------------------------------------------------------
    // Write
    //
    // Used later for SW.
    // For LW, mem_write = 0.
    // --------------------------------------------------------

    always_ff @(posedge clk) begin

        if (mem_write)
            memory[address[9:2]] <= write_data;

    end

endmodule


// ============================================================
// 9. MEM / WB PIPELINE REGISTER
// ============================================================

module mem_wb_reg (
    input  logic        clk,
    input  logic        rst,

    input  logic [31:0] memory_data_in,
    input  logic [31:0] alu_result_in,

    input  logic [4:0]  rd_in,

    input  logic        reg_write_in,
    input  logic        mem_to_reg_in,

    output logic [31:0] memory_data_out,
    output logic [31:0] alu_result_out,

    output logic [4:0]  rd_out,

    output logic        reg_write_out,
    output logic        mem_to_reg_out
);

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            memory_data_out <= 32'd0;
            alu_result_out  <= 32'd0;

            rd_out <= 5'd0;

            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;

        end

        else begin

            memory_data_out <= memory_data_in;
            alu_result_out  <= alu_result_in;

            rd_out <= rd_in;

            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;

        end

    end

endmodule


// ============================================================
// 10. WB STAGE
// ============================================================

module wb_stage (
    input  logic        mem_to_reg,

    input  logic [31:0] alu_result,
    input  logic [31:0] memory_data,

    output logic [31:0] write_data
);

    always_comb begin

        if (mem_to_reg)
            write_data = memory_data;

        else
            write_data = alu_result;

    end

endmodule


// ============================================================
// 11. TOP MODULE
// ============================================================

module rv32_lw_pipeline (
    input logic clk,
    input logic rst
);

    // ========================================================
    // IF
    // ========================================================

    logic [31:0] pc_if;
    logic [31:0] instr_if;


    // ========================================================
    // IF / ID
    // ========================================================

    logic [31:0] pc_id;
    logic [31:0] instr_id;


    // ========================================================
    // ID
    // ========================================================

    logic [4:0] rs1_id;
    logic [4:0] rd_id;

    logic [31:0] immediate_id;
    logic [31:0] rs1_data_id;

    logic reg_write_id;
    logic mem_read_id;
    logic mem_write_id;
    logic alu_src_id;
    logic mem_to_reg_id;


    // ========================================================
    // ID / EX
    // ========================================================

    logic [31:0] rs1_data_ex;
    logic [31:0] immediate_ex;

    logic [4:0] rd_ex;

    logic reg_write_ex;
    logic mem_read_ex;
    logic mem_write_ex;
    logic alu_src_ex;
    logic mem_to_reg_ex;


    // ========================================================
    // EX
    // ========================================================

    logic [31:0] alu_result_ex;


    // ========================================================
    // EX / MEM
    // ========================================================

    logic [31:0] address_mem;
    logic [4:0] rd_mem;

    logic reg_write_mem;
    logic mem_read_mem;
    logic mem_write_mem;
    logic mem_to_reg_mem;


    // ========================================================
    // MEM
    // ========================================================

    logic [31:0] memory_data_mem;


    // ========================================================
    // MEM / WB
    // ========================================================

    logic [31:0] memory_data_wb;
    logic [31:0] alu_result_wb;

    logic [4:0] rd_wb;

    logic reg_write_wb;
    logic mem_to_reg_wb;


    // ========================================================
    // WB
    // ========================================================

    logic [31:0] write_data_wb;


    // ========================================================
    // REGISTER FILE
    // ========================================================

    logic [31:0] rs2_data_unused;


    // ========================================================
    // IF
    // ========================================================

    if_stage IF (
        .clk         (clk),
        .rst         (rst),

        .pc          (pc_if),
        .instruction (instr_if)
    );


    // ========================================================
    // IF -> ID
    // ========================================================

    if_id_reg IF_ID (
        .clk       (clk),
        .rst       (rst),

        .pc_in     (pc_if),
        .instr_in  (instr_if),

        .pc_out    (pc_id),
        .instr_out (instr_id)
    );


    // ========================================================
    // REGISTER FILE
    //
    // ID reads x1.
    // WB writes the final result.
    // ========================================================

    register_file REGFILE (
        .clk        (clk),

        .rs1        (rs1_id),
        .rs2        (5'd0),

        .rs1_data   (rs1_data_id),
        .rs2_data   (rs2_data_unused),

        .reg_write  (reg_write_wb),
        .rd         (rd_wb),
        .write_data (write_data_wb)
    );


    // ========================================================
    // ID
    // ========================================================

    id_stage ID (
        .instr       (instr_id),

        .rs1         (rs1_id),
        .rd          (rd_id),

        .immediate   (immediate_id),

        .reg_write   (reg_write_id),
        .mem_read    (mem_read_id),
        .mem_write   (mem_write_id),
        .alu_src     (alu_src_id),
        .mem_to_reg  (mem_to_reg_id)
    );


    // ========================================================
    // ID -> EX
    // ========================================================

    id_ex_reg ID_EX (
        .clk             (clk),
        .rst             (rst),

        .rs1_data_in     (rs1_data_id),
        .immediate_in    (immediate_id),

        .rd_in           (rd_id),

        .reg_write_in    (reg_write_id),
        .mem_read_in     (mem_read_id),
        .mem_write_in    (mem_write_id),
        .alu_src_in      (alu_src_id),
        .mem_to_reg_in   (mem_to_reg_id),

        .rs1_data_out    (rs1_data_ex),
        .immediate_out   (immediate_ex),

        .rd_out          (rd_ex),

        .reg_write_out   (reg_write_ex),
        .mem_read_out    (mem_read_ex),
        .mem_write_out   (mem_write_ex),
        .alu_src_out     (alu_src_ex),
        .mem_to_reg_out  (mem_to_reg_ex)
    );


    // ========================================================
    // EX
    //
    // Calculates:
    //
    //     base register + offset
    //
    // Example:
    //
    //     x1 = 1000
    //     immediate = 8
    //
    //     ALU result = 1008
    // ========================================================

    ex_stage EX (
        .rs1_data   (rs1_data_ex),
        .immediate  (immediate_ex),

        .alu_src    (alu_src_ex),

        .alu_result (alu_result_ex)
    );


    // ========================================================
    // EX -> MEM
    //
    // alu_result_ex becomes the memory address.
    // ========================================================

    ex_mem_reg EX_MEM (
        .clk             (clk),
        .rst             (rst),

        .alu_result_in   (alu_result_ex),
        .rd_in           (rd_ex),

        .reg_write_in    (reg_write_ex),
        .mem_read_in     (mem_read_ex),
        .mem_write_in    (mem_write_ex),
        .mem_to_reg_in   (mem_to_reg_ex),

        .alu_result_out  (address_mem),
        .rd_out          (rd_mem),

        .reg_write_out   (reg_write_mem),
        .mem_read_out    (mem_read_mem),
        .mem_write_out   (mem_write_mem),
        .mem_to_reg_out  (mem_to_reg_mem)
    );


    // ========================================================
    // MEM
    //
    // IMPORTANT:
    //
    // address_mem comes directly from EX/MEM.
    // ========================================================

    data_memory DMEM (
        .clk        (clk),

        .mem_read  (mem_read_mem),
        .mem_write (mem_write_mem),

        .address   (address_mem),

        .write_data(32'd0),

        .read_data (memory_data_mem)
    );


    // ========================================================
    // MEM -> WB
    // ========================================================

    mem_wb_reg MEM_WB (
        .clk             (clk),
        .rst             (rst),

        .memory_data_in  (memory_data_mem),
        .alu_result_in   (address_mem),

        .rd_in           (rd_mem),

        .reg_write_in    (reg_write_mem),
        .mem_to_reg_in   (mem_to_reg_mem),

        .memory_data_out (memory_data_wb),
        .alu_result_out  (alu_result_wb),

        .rd_out          (rd_wb),

        .reg_write_out   (reg_write_wb),
        .mem_to_reg_out  (mem_to_reg_wb)
    );


    // ========================================================
    // WB
    // ========================================================

    wb_stage WB (
        .mem_to_reg  (mem_to_reg_wb),

        .alu_result  (alu_result_wb),
        .memory_data (memory_data_wb),

        .write_data  (write_data_wb)
    );

endmodule
