//-----------------------------------------
//	5-Stage Multicycle MIPS I
//-----------------------------------------
module MIPS (

	/* NOTE
 	 * The names of these inputs/outputs cannot be changed.
 	 * They are referenced directly by the test bench.
 	 * Renaming will result in the program failing to compile.
 	 */

	//MODULE INPUTS

		input 		CLOCK,
		input 		RESET,

		input [31:0] 	Instruction_IN,		//INSTRUCTION FROM INSTRUCTION MEMORY
		input [31:0] 	Data_IN,		//DATA FROM DATA MEMORY

		/* verilator lint_off UNUSED */
		input [255:0]	InstructionBlock_IN,
		input [255:0]	DataBlock_IN,
		/* verilator lint_on UNUSED */

	//MODULE OUTPUTS

		output [31:0] 	InstructionAddress_OUT,	//ADDRESS OF INSTRUCTION TO FETCH FROM INSTRUCTION MEMORY
		output [31:0] 	DataAddress_OUT,	//ADDRESS OF DATA MEMORY WE WANT TO INTERACT WITH (Read/Write)

		/* NOTE
 		 * DataSize_OUT follows the convention:
 		 * 1 byte: 	1
 		 * 2 bytes:  	2
 		 * 3 bytes: 	3
 		 * 4 bytes: 	0
 		 */

		output [31:0] 	Data_OUT,		//DATA TO WRITE TO DATA MEMORY
		output [1:0] 	DataSize_OUT,		//NUMBER OF BYTES TO WRITE TO DATA MEMORY
		output 		MemRead_OUT,		//TELL DATA MEMORY WE WANT TO READ
		output 		MemWrite_OUT,		//TELL DATA MEMORY WE WANT TO WRITE

		output 		SYS,			//TELL THE SYSTEM TO EXECUTE A SYSCALL

		/* verilator lint_off UNUSED */
		output [255:0] 	DataBlock_OUT,		//Data being written
		output 		MemBlockRead_OUT,	//Request a block read
		output 		MemBlockWrite_OUT	//Request a block write
		/* verilator lint_on UNUSED */

);

//-----------------------------------
//WIRES ORIGINATING FROM THE IF STAGE
//-----------------------------------

	//IF --> IF/ID
	wire [31:0]	InstructionAddressPlus4_IFtoIFID;

	//IF --> IM
	wire [31:0]	InstructionAddress_IFtoIM;

//-----------------------------------------
//WIRES ORIGINATING FROM THE IF/ID REGISTER
//-----------------------------------------

	//IF/ID --> ID
	wire [31:0] Instruction_IFIDtoID;
	wire [31:0] InstructionAddressPlus4_IFIDtoID;

//-----------------------------------
//WIRES ORIGINATING FROM THE ID STAGE
//-----------------------------------

	//ID --> IF
	wire [31:0]	AltPC_IDtoIF;
	wire 		AltPCEnable_IDtoIF;

	//ID --> ID/EXE
	wire [31:0]	OperandA_IDtoIDEXE;
	wire [31:0]	OperandB_IDtoIDEXE;
	wire [5:0]	ALUControl_IDtoIDEXE;
	wire [4:0]	ShiftAmount_IDtoIDEXE;

	wire [31:0]	MemWriteData_IDtoIDEXE;
	wire		MemRead_IDtoIDEXE;
	wire		MemWrite_IDtoIDEXE;

	wire [4:0]	WriteRegister_IDtoIDEXE;
	wire 		WriteEnable_IDtoIDEXE;

	//ID --> forward
	wire	     AltPCEnable_IDtoForward;
	wire [4:0]   IDRegisterRS_IDtoForward;
	wire [4:0]   IDRegisterRT_IDtoForward;
	wire [5:0]   OpcodeID_IDtoForward;
	//ID --> EXE
	wire	RegDest_IDtoEXE;
	//ID --> HAZARD
	wire Jumb_IDtoHazard;
	wire Branch_IDtoHazard;
	wire [4:0]   IDRegisterRS_IDtoHazard;
	wire [4:0]   IDRegisterRT_IDtoHazard;

//------------------------------------------
//WIRES ORIGINATING FROM THE ID/EXE REGISTER
//------------------------------------------

	//ID/EXE --> EXE
	wire [31:0] 	OperandA_IDEXEtoEXE;
	wire [31:0] 	OperandB_IDEXEtoEXE;
	wire [5:0]  	ALUControl_IDEXEtoEXE;
	wire [4:0]  	ShiftAmount_IDEXEtoEXE;

	//ID/EXE --> EXE/MEM
	wire [31:0] 	MemWriteData_IDEXEtoEXEMEM;
	wire        	MemRead_IDEXEtoEXEMEM;
	wire        	MemWrite_IDEXEtoEXEMEM;

	wire [4:0]  	WriteRegister_IDEXEtoEXEMEM;
	wire        	WriteEnable_IDEXEtoEXEMEM;
	//IDEXE --> HAZARD
	wire [4:0] WriteRegister_IDEXEtoHazard;
	wire        	WriteEnable_IDEXEtoHazard;
//------------------------------------
//WIRES ORIGINATING FROM THE EXE STAGE
//------------------------------------

	//EXE --> EXE/MEM
	wire [31:0] 	ALUResult_EXEtoEXEMEM;
	//EXE-->Forward
	wire [31:0] 	ALUResult_EXEtoFROWARD;
	wire [4:0]      writeRegister_EXEtoFROWARD;
	wire            writeEnable_EXEtoFORWARD;
	//-------------------------------------------
//WIRES ORIGINATING FROM THE EXE/MEM REGISTER
//-------------------------------------------

	//EXE/MEM --> MEM
	wire [31:0] 	MemWriteData_EXEMEMtoMEM;
	wire [5:0] 	MemControl_EXEMEMtoMEM;
	wire 		MemRead_EXEMEMtoMEM;

	wire [31:0] 	ALUResult_EXEMEMtoMEM;

	//EXE/MEM --> MEM/WB
	wire [4:0] 	WriteRegister_EXEMEMtoMEMWB;
	wire 		WriteEnable_EXEMEMtoMEMWB;

	//EXE/MEM --> DM
	wire		MemWrite_EXEMEMtoDM;

	//ECE/MEM -->Forward
	wire [4:0] writeRegister_EXEMEMtoFORWARD;
	wire       writeEnable_EXEMEMtoFORWARD;

	//EXE/MEM --> EXEM
	wire [31:0] EXEMEMALUResult_EXEMEMtoEXE;

	//EXE/MEM --> ID
	wire [31:0] EXEMEMALUResult_EXEMEMtoID;
	//EXE/MEM --> HAZARD
	wire [4:0] WriteRegister_EXEMEMtoHazard;
	wire MemRead_EXEMEMtoHazard;

//------------------------------------
//WIRES ORIGINATING FROM THE MEM STAGE
//------------------------------------

	//MEM --> MEM/WB
	wire [31:0] 	WriteData_MEMtoMEMWB;

	//MEM --> DM
	wire [31:0]	Data_MEMtoDM;
	wire [1:0]	DataSize_MEMtoDM;

//------------------------------------------
//WIRES ORIGINATING FROM THE MEM/WB REGISTER
//------------------------------------------

	//MEM/WB --> ID
	wire [31:0] 	WriteData_MEMWBtoID;
	wire [4:0]  	WriteRegister_MEMWBtoID;
	wire        	WriteEnable_MEMWBtoID;

	//MEM/WB --> EXE
	wire [31:0] MEMWBWriteData_MEMWBtoEXE;

	//MEM/WB --> Forward
	wire [4:0] 	WriteRegister_MEMWBtoForward;
	wire            WriteEnable_MEMWbtoForward;
//-----------------------------------------
//WIRES ORIGINATING FROM INSTRUCTION MEMORY
//-----------------------------------------

	//IM --> IF/ID
	wire [31:0] 	Instruction_IMtoIFID;

//----------------------------------
//WIRES ORIGINATING FROM DATA MEMORY
//----------------------------------

	//DM --> MEM
	wire [31:0]	Data_DMtoMEM;

//------------------------------------------
//WIRES ORIGINATING FROM THE FORWARDING UNIT
//------------------------------------------
	//Forward --> EXE
	wire [1:0] ForwardRS_FORWARDtoEXE;
	wire [1:0] ForwardRT_FORWARDtoEXE;

	//Forward ta_MEMWBtoID
	wire [1:0] ForwardRSbranch_FORWARDtoID;
	wire [1:0] ForwardRTbranch_FORWARDtoID;
	//trial to debugg
//------------------------------------------------
//WIRES ORIGINATING FROM THE HAZARD DETECTION UNIT
//------------------------------------------------

	//HAZARD --> IF/ID
	wire 	STALL_toIFID;
	wire 	FLUSH_toIFID;

	//HAZARD --> ID/EXE
	wire 	STALL_toIDEXE;
	wire 	FLUSH_toIDEXE;

	//HAZARD --> EXE/MEM
	wire 	STALL_toEXEMEM;
	wire 	FLUSH_toEXEMEM;

	//HAZARD --> MEM/WB
	wire 	STALL_toMEMWB;
	wire 	FLUSH_toMEMWB;


//DISABLE BLOCK READ/WRITE
assign MemBlockRead_OUT		= 1'b0;
assign MemBlockWrite_OUT	= 1'b0;
assign DataBlock_OUT		= 256'b0;

//PROCESSOR INPUTS
assign Instruction_IMtoIFID 	= Instruction_IN;
assign Data_DMtoMEM 		= Data_IN;

//PROCESSOR OUTPUTS
assign InstructionAddress_OUT 	= InstructionAddress_IFtoIM;
assign Data_OUT 		= Data_MEMtoDM;
assign DataAddress_OUT 		= ALUResult_EXEMEMtoMEM;
assign DataSize_OUT 		= DataSize_MEMtoDM;
assign MemRead_OUT 		= MemRead_EXEMEMtoMEM;
assign MemWrite_OUT 		= MemWrite_EXEMEMtoDM;

//INSTRUCTION FETCH STAGE
IF IF(

	//MODULE INPUTS

		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),
		.STALL(STALL_toIFID),

		//ID --> IF
		.AltPC_IN(AltPC_IDtoIF),
		.AltPCEnable_IN(AltPCEnable_IDtoIF),

	//MODULE OUTPUTS

		//IF --> IF/ID
		.InstructionAddressPlus4_OUT(InstructionAddressPlus4_IFtoIFID),

		//IF --> IM
		.InstructionAddress_OUT(InstructionAddress_IFtoIM)

);

//IF/ID REGISTER
IFID IFID(

	//MODULE INPUTS

		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),
		.STALL(STALL_toIFID),
		.FLUSH(FLUSH_toIFID),

		//INFORMATION FOR ID STAGE
		.Instruction_IN(Instruction_IMtoIFID),
		.InstructionAddressPlus4_IN(InstructionAddressPlus4_IFtoIFID),

	//MODULE OUTPUTS

		//INFORMATION FOR ID STAGE
		.Instruction_OUT(Instruction_IFIDtoID),
		.InstructionAddressPlus4_OUT(InstructionAddressPlus4_IFIDtoID)

);

//INSTRUCTION DECODE STAGE
ID ID(

	//MODULE INPUTS

		//GLOBAL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),

		//MEM/WB --> ID
		.WriteEnable_IN(WriteEnable_MEMWBtoID),
		.WriteData_IN(WriteData_MEMWBtoID),
		.WriteRegister_IN(WriteRegister_MEMWBtoID),

		//IF/ID --> ID
		.Instruction_IN(Instruction_IFIDtoID),
		.InstructionAddressPlus4_IN(InstructionAddressPlus4_IFIDtoID),
		.ForwardRSbranch_IN(ForwardRSbranch_FORWARDtoID),
		.ForwardRTbranch_IN(ForwardRTbranch_FORWARDtoID),

		//EXE/MEM --> ID
		.ALUResultID_IN(EXEMEMALUResult_EXEMEMtoID),
	//MODULE OUTPUTS

		.Syscall_OUT(SYS),

		//ID --> IF
		//
		.AltPC_OUT(AltPC_IDtoIF),

		//ID --> ID/EXE
		.OperandA_OUT(OperandA_IDtoIDEXE),
		.OperandB_OUT(OperandB_IDtoIDEXE),
		.ALUControl_OUT(ALUControl_IDtoIDEXE),
		.ShiftAmount_OUT(ShiftAmount_IDtoIDEXE),

		.MemWriteData_OUT(MemWriteData_IDtoIDEXE),
 		.MemRead_OUT(MemRead_IDtoIDEXE),
		.MemWrite_OUT(MemWrite_IDtoIDEXE),

		.WriteRegister_OUT(WriteRegister_IDtoIDEXE),
		.WriteEnable_OUT(WriteEnable_IDtoIDEXE),
		//ID --> Forward\
		.AltPCEnable_OUT(AltPCEnable_IDtoForward || AltPCEnable_IDtoIF),
		.IDRegisterRS_OUT(IDRegisterRS_IDtoForward || IDRegisterRS_IDtoHazard),
		.IDRegisterRT_OUT(IDRegisterRT_IDtoForward || IDRegisterRT_IDtoHazard),
		.OpcodeID_OUT(OpcodeID_IDtoForward),
		//ID --> EXE
		.RegDest_OUT(RegDest_IDtoEXE),
		//ID --> HAZARD
		.Jumb_OUT(Jumb_IDtoHazard),
		.Branch_OUT(Branch_IDtoHazard)
);

//ID/EXE REGISTER
IDEXE IDEXE(

	//MODULE INPUTS

		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),
		.STALL(STALL_toIDEXE),
		.FLUSH(FLUSH_toIDEXE),

		//EXE STAGE INFORMATION
		.OperandA_IN(OperandA_IDtoIDEXE),
		.OperandB_IN(OperandB_IDtoIDEXE),
		.ALUControl_IN(ALUControl_IDtoIDEXE),
		.ShiftAmount_IN(ShiftAmount_IDtoIDEXE),

		//MEM STAGE INFORMATION
		.MemWriteData_IN(MemWriteData_IDtoIDEXE),
		.MemRead_IN(MemRead_IDtoIDEXE),
		.MemWrite_IN(MemWrite_IDtoIDEXE),

		//WB STAGE INFORMATION
		.WriteRegister_IN(WriteRegister_IDtoIDEXE),
		.WriteEnable_IN(WriteEnable_IDtoIDEXE),

	//MODULE OUTPUTS

		//EXE STAGE INFORMATION
		.OperandA_OUT(OperandA_IDEXEtoEXE),
		.OperandB_OUT(OperandB_IDEXEtoEXE),
		.ALUControl_OUT(ALUControl_IDEXEtoEXE),
		.ShiftAmount_OUT(ShiftAmount_IDEXEtoEXE),

		//MEM STAGE INFORMATION
		.MemWriteData_OUT(MemWriteData_IDEXEtoEXEMEM),
		.MemRead_OUT(MemRead_IDEXEtoEXEMEM),
		.MemWrite_OUT(MemWrite_IDEXEtoEXEMEM),

		//WB STAGE INFORMATION
		.WriteRegister_OUT(WriteRegister_IDEXEtoEXEMEM ||WriteRegister_IDEXEtoHazard),
		.WriteEnable_OUT(WriteEnable_IDEXEtoEXEMEM || WriteEnable_IDEXEtoHazard),

);

//EXECUTION STAGE
EXE EXE(

	//MODULE INPUTS
		//EXEMEM --> EXE
		.ALUResult_IN(EXEMEMALUResult_EXEMEMtoEXE),

		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),
		//ID --> EXE
		.RegDest_IN(RegDest_IDtoEXE),

		//ID/EXE --> EXE
		.OperandA_IN(OperandA_IDEXEtoEXE),
		.OperandB_IN(OperandB_IDEXEtoEXE),
		.ALUControl_IN(ALUControl_IDEXEtoEXE),
		.ShiftAmount_IN(ShiftAmount_IDEXEtoEXE),

		//Forward --> EXE
		.ForwardRS_IN(ForwardRS_FORWARDtoEXE),
		.ForwardRT_IN(ForwardRT_FORWARDtoEXE),

		//MEM?WB --> EXE
		.MEMWBWriteData_IN(MEMWBWriteData_MEMWBtoEXE),
	//MODULE OUTPUTS

		//EXE --> EXE/MEM
		//.ALUResult_OUT(ALUResult_EXEtoEXEMEM),

		//EXE --> forward
		.ALUResult_OUT(ALUResult_EXEtoFROWARD||ALUResult_EXEtoEXEMEM)



);
//EXE/MEM REGISTER
EXEMEM EXEMEM(

	//MODULE INPUTS

		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),
		.STALL(STALL_toEXEMEM),
		.FLUSH(FLUSH_toEXEMEM),

		//INFORMATION FOR MEM STAGE
		.MemRead_IN(MemRead_IDEXEtoEXEMEM),
		.MemWrite_IN(MemWrite_IDEXEtoEXEMEM),
		.MemControl_IN(ALUControl_IDEXEtoEXE),
		.MemWriteData_IN(MemWriteData_IDEXEtoEXEMEM),

		//INFORMATION FOR WB STAGE
		.ALUResult_IN(ALUResult_EXEtoEXEMEM),
		.WriteRegister_IN(WriteRegister_IDEXEtoEXEMEM),
		.WriteEnable_IN(WriteEnable_IDEXEtoEXEMEM),

	//MODULE OUTPUTS

		//INFORMATION FOR MEM STAGE
		.MemRead_OUT(MemRead_EXEMEMtoMEM ||MemRead_EXEMEMtoHazard),
		.MemWrite_OUT(MemWrite_EXEMEMtoDM),
		.MemControl_OUT(MemControl_EXEMEMtoMEM),
		.MemWriteData_OUT(MemWriteData_EXEMEMtoMEM),

		//INFORMATION FOR WB STAGE
		//.ALUResult_OUT(ALUResult_EXEMEMtoMEM),
		//.WriteRegister_OUT(WriteRegister_EXEMEMtoMEMWB),
		//.WriteEnable_OUT(WriteEnable_EXEMEMtoMEMWB),

		//EXEMEM --> forward
		.WriteRegister_OUT(writeRegister_EXEMEMtoFORWAR || WriteRegister_EXEMEMtoMEMWBD || WriteRegister_EXEMEMtoHazard),
		.WriteEnable_OUT(writeEnable_EXEMEMtoFORWARD||WriteEnable_EXEMEMtoMEMWB),

		//EXEMEM --> EXE
		.ALUResult_OUT(EXEMEMALUResult_EXEMEMtoEXE||ALUResult_EXEMEMtoMEM ||EXEMEMALUResult_EXEMEMtoID)
);

MEM MEM(

	//MODULE INPUTS

		//EXE/MEM --> MEM
		.MemRead_IN(MemRead_EXEMEMtoMEM),
		.MemControl_IN(MemControl_EXEMEMtoMEM),
		.ALUResult_IN(ALUResult_EXEMEMtoMEM),
		.MemWriteData_IN(MemWriteData_EXEMEMtoMEM),

		//DM --> MEM
		.Data_IN(Data_DMtoMEM),


	//MODULE OUTPUTS

		//MEM --> DM
		.DataSize_OUT(DataSize_MEMtoDM),
		.Data_OUT(Data_MEMtoDM),

		//MEM --> MEM/WB
		.WriteData_OUT(WriteData_MEMtoMEMWB)
);

MEMWB MEMWB(

	//MODULE INPUTS

		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),
		.STALL(STALL_toMEMWB),
		.FLUSH(FLUSH_toMEMWB),

		//INFORMATION FOR WB STAGE
		.WriteData_IN(WriteData_MEMtoMEMWB),
		.WriteRegister_IN(WriteRegister_EXEMEMtoMEMWB),
		.WriteEnable_IN(WriteEnable_EXEMEMtoMEMWB),

	//MODULE OUTPUTS

		//INFORMATION FOR WB STAGE
		//.WriteData_OUT(WriteData_MEMWBtoID),
		//.WriteRegister_OUT(WriteRegister_MEMWBtoID),
		//.WriteEnable_OUT(WriteEnable_MEMWBtoID)

		//MEMWB -->Forward
		.WriteRegister_OUT(WriteRegister_MEMWBtoForward||WriteRegister_MEMWBtoID),
		.WriteEnable_OUT(WriteEnable_MEMWbtoForward||WriteEnable_MEMWBtoID),

		//MEMWB --> EXE
		.WriteData_OUT(MEMWBWriteData_MEMWBtoEXE||WriteData_MEMWBtoID)
);


Hazard Hazard(

	//MODULE INPUTS

		//CONTROL SIGNALS
		.CLOCK(CLOCK),
		.RESET(RESET),

		//ID --> HAZARD
		.Jumb_IN(Jumb_IDtoHazard),
		.Branch_IN(Branch_IDtoHazard),
		.IDRegisterRS_IN(IDRegisterRS_IDtoHazard),
		.IDRegisterRT_IN(IDRegisterRT_IDtoHazard),
		//IDEXE --> HAZARD
		.IDEXEWriteRegister_IN(WriteRegister_IDEXEtoHazard),
		.IDEXEWriteEnable_IN(WriteEnable_IDEXEtoHazard),

	//MODULE OUTPUTS

		//HAZARD --> IF/ID
		.STALL_IFID(STALL_toIFID),
		.FLUSH_IFID(FLUSH_toIFID),

		//HAZARD --> ID/EXE
		.STALL_IDEXE(STALL_toIDEXE),
		.FLUSH_IDEXE(FLUSH_toIDEXE),

		//HAZARD --> EXE/MEM
		.STALL_EXEMEM(STALL_toEXEMEM),
		.FLUSH_EXEMEM(FLUSH_toEXEMEM),

		//HAZARD --> MEM/WB
		.STALL_MEMWB(STALL_toMEMWB),
		.FLUSH_MEMWB(FLUSH_toMEMWB)

);

Forward Forward(

	//MODULE INPUTS
	.CLOCK(CLOCK),
	.RESET(RESET),
		//EXE --> forward
	.ALUResult_OUT(ALUResult_EXEtoFROWARD),
		//EXE/MEM
	.writeRDEXEMEM(writeRegister_EXEMEMtoFORWARD),
	.writeEnableEXEMEM(writeEnable_EXEMEMtoFORWARD),
		//MEM/WB --> forward
	.writeRDMEMWB(WriteRegister_MEMWBtoForward),
	.writeEnableMEMWB(WriteEnable_MEMWbtoForward),
		//ID --> forward
	.AltPCEnable_IN(AltPCEnable_IDtoForward),
	.IDRegisterRS_IN(IDRegisterRS_IDtoForward),
	.IDRegisterRT_IN(IDRegisterRT_IDtoForward),
	.OpcodeID_IN(OpcodeID_IDtoForward),
	//MODULE OUTPUTS
	.ForwardRS_OUT(ForwardRS_FORWARDtoEXE),
	.ForwardRT_OUT(ForwardRT_FORWARDtoEXE),
	.ForwardRSbranch_out(ForwardRSbranch_FORWARDtoID),
	.ForwardRTbranch_out(ForwardRTbranch_FORWARDtoID)

);

endmodule
