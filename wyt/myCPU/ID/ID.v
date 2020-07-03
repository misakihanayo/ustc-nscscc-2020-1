`timescale 1ns / 1ps

module ID_module(
    //global
    input clk,
    input rst,

    //from IF/ID reg
    input [31:0] instr,
    input [31:0] pc_plus_4,
    input [31:0] PCin,

    //from WB
    input [6:0] WriteRegW,
    input [31:0] ResultW,
    input [63:0] HI_LO_data,
    input HI_LO_write_enable_from_WB,
    input RegWriteW,

    //from EX
    input [31:0] ALUoutE,

    //from MEM
    input [31:0] ALUoutM,
    input [31:0] RAMoutM,

    //from Hazard Unit
    input [1:0] ForwardAD,
    input [1:0] ForwardBD,

    //from Exception_module
    input [31:0] we,
    input [7:0] interrupt_enable,
    input [4:0] Exception_code,
    input EXL,
    input [31:0] epc,
    input [31:0] BADADDR,
    input  Branch_delay,

    //from External interruption
    input [5:0] hardware_interruption,
    input [1:0] software_interruption,

    //to ID/EX reg
        output [5:0] ALUOp,
        //outputs from ctl_unit
        output HI_LO_write_enableD,
        output [2:0] MemReadType,
        output MemReadD,
        output RegWriteD,
        output MemtoRegD,
        output MemWriteD,
        output ALUSrcDA,
        output ALUSrcDB,
        output RegDstD,
        output Imm_sel_and_Branch_taken,
        //outputs from reg_file
        output [31:0] RsValue,
        output [31:0] RtValue,
        //outputs from Instr
        output [31:0] pc_plus_8,
        output [6:0] Rs,
        output [6:0] Rt, 
        output [6:0] Rd,
        output [15:0] imm,
        output [31:0] PCout,
    //to IF stage
    output EPC_sel,
    output BranchD,
    output Jump,
    output [31:0] PCSrc_reg,
    output [31:0] EPC,
    output [31:0] Branch_addr,
    output [31:0] Jump_addr,
    //to IF/ID stage
    output CLR_EN,
    //to Harzard unit
    output exception,
    output isBranch,
    //to Exception_module
    output [31:0] Status_data,
    output [31:0] cause_data
    //Line 32-38 41-42 81-82 are added by Gaoustcer
    );

    wire Imm_sel, Branch_taken, RegWriteCD, RegWriteBD;
    wire [31:0] Read_data_1, Read_data_2;

    assign pc_plus_8 = pc_plus_4 + 4;
    assign branch_addr = pc_plus_4 + {{14{imm[15]}},imm,2'b00};
    assign jump_addr = {pc_plus_4[31:28], instr[25:0], 2'b00};
    assign Imm_sel_and_Branch_taken = Imm_sel & Branch_taken;
    assign CLR_EN = Jump | BranchD;
    assign RegWriteD = RegWriteBD | RegWriteCD;
    assign PCSrc_reg = RsValue;
    assign PCout = PCin;

    mux_4 rd1_mux(.m(ForwardAD),
                .in_0(Read_data_1),
                .in_1(ALUoutE),
                .in_2(RAMoutM),
                .in_3(ALUoutM),
                .out(RsValue));

    mux_4 rd2_mux(.m(ForwardBD),
                .in_0(Read_data_2),
                .in_1(ALUoutE),
                .in_2(RAMoutM),
                .in_3(ALUoutM),
                .out(RtValue));

    Control_Unit CPU_CTL(.Op(instr[31:26]),
                        .func(instr[5:0]),

                        .EPC_sel(EPC_sel),
                        .HI_LO_write_enableD(HI_LO_write_enableD),
                        .MemReadType(MemReadType),
                        .Jump(Jump),
                        .MemReadD(MemReadD),
                        .RegWriteCD(RegWriteCD),
                        .MemtoRegD(MemtoRegD),
                        .MemWriteD(MemWriteD),
                        .ALUSrcDA(ALUSrcDA),
                        .ALUSrcDB(ALUSrcDB),
                        .RegDstD(RegDstD),
                        .Imm_sel(Imm_sel),
                        .isBranch(isBranch)
    );

    register_file reg_file(.clk(clk),
                           .rst(rst),
                           .regwrite(RegWriteW),
                           .hl_write_enable_from_wb(HI_LO_write_enable_from_WB),
                           .read_addr_1(Rs),
                           .read_addr_2(Rd),
                           .hl_data(HI_LO_data),
                           .write_addr(WriteRegW),
                           .write_data(ResultW),
                           .read_data_1(Read_data_1),
                           .read_data_2(Read_data_2),
                           .EPC_data(EPC),
                           .hardware_interruption(hardware_interruption),
                           .software_interruption(software_interruption),
                           .we(we),
                           .interrupt_enable(interrupt_enable),
                            .Exception_code(Exception_code),
                            .EXL(EXL),
                            .epc(epc),
                            .BADADDR(BADADDR),
                            .Branch_delay(Branch_delay),
                            .Status_data(Status_data),
                            .cause_data(cause_data)
                            );

    Branch_judge brch_jdg(.Op(instr[31:26]),
                          .rt(instr[20:16]),
                          .RsValue(RsValue),
                          .RtValue(RtValue),
                          .RegWriteBD(RegWriteBD),
                          .BranchD(BranchD),
                          .branch_taken(Branch_taken));

    decoder dcd(.ins(instr[31:0]),
               .ALUop(ALUop),
               .Rs(Rs),
               .Rt(Rt),
               .Rd(Rd),
               .imm(imm),
               .exception(exception));
    
endmodule
