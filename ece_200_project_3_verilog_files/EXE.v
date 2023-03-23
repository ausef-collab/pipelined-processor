module EXE(

	//MODULE INPUTS

		//CONTROL SIGNALS
		input CLOCK,
		input RESET,
		//ID --> EXE
		input 		RegDest_IN,
		//ID/EXE --> EXE
		input [31:0] 	OperandA_IN,
		input [31:0] 	OperandB_IN,
		input [5:0]  	ALUControl_IN,
		input [4:0]  	ShiftAmount_IN,
		//EXEMEM --> EXE
		input [31:0]  ALUResult_IN,

		//MEM?WB --> EXE
		input [31:0] MEMWBWriteData_IN,
		//Forward --> EXE
		input [1:0] ForwardRS_IN,
		input [1:0] ForwardRT_IN,
	//MODULE OUTPUT

		//EXE --> EXE/MEM
		output [31:0] 	ALUResult_OUT

);

wire [31:0] OperandA_NEW;
wire [31:0] OperandB_NEW;
reg [31:0] HI/*verilator public*/;
reg [31:0] LO/*verilator public*/;

wire [31:0] newHI;
wire [31:0] newLO;

always @(posedge CLOCK or negedge RESET) begin
if(ForwardRS_IN== 2'b10)begin
assign OperandA_NEW =ALUResult_IN;
$display("forward (RS) pass from EXEMEM,\nforwarded value: %d\n old vaule: ", OperandA_NEW,OperandA_IN);
end
else if (ForwardRS_IN==2'b01)begin
assign OperandA_NEW =MEMWBWriteData_IN;
$display("forward (RS)pass from MEMWB,\nforwarded value:  %d\n old vaule: ", OperandA_NEW,OperandA_IN);
end
else begin
assign OperandA_NEW =OperandA_IN;
$display("No forwarding needed\n");
end
end

always @(posedge CLOCK or negedge RESET) begin
if(RegDest_IN)begin
	if(ForwardRT_IN==2'b10)begin
	assign OperandB_NEW =ALUResult_IN;
	$display("forward (RT) pass from EXEMEM, %d\n old vaule: ", OperandB_NEW,OperandB_IN);
	end
	else if (ForwardRT_IN==2'b01)begin
	assign OperandB_NEW =MEMWBWriteData_IN;
	$display("forward (RT) pass from MEMWB, %d\n old vaule: ", OperandB_NEW,OperandB_IN);
	end
	else begin
	assign OperandB_NEW =OperandB_IN;
	$display("No forwarding needed\n");
	end
end
end


ALU ALU(

	//MODULE INPUTS
	.HI_IN(HI),
	.LO_IN(LO),
	.OperandA_IN(OperandA_NEW), //need to change to new oprands for both
	.OperandB_IN(OperandB_NEW),
	.ALUControl_IN(ALUControl_IN),
	.ShiftAmount_IN(ShiftAmount_IN),

	//MODULE OUTPUTS
	.ALUResult_OUT(ALUResult_OUT),
	.HI_OUT(newHI),
	.LO_OUT(newLO)

);

//ON THE RISING EDGE OF THE CLOCK OR FALLING EDGE OF RESET
always @(posedge CLOCK or negedge RESET) begin

	//IF THE MODULE HAS BEEN RESET
	if(!RESET) begin

		HI <= 0;
		LO <= 0;

	//ELSE IF THE CLOCK HAS RISEN
	end else if(CLOCK) begin

		HI <= newHI;
		LO <= newLO;

		$display("");
		$display("----- EXE -----");
		$display("HI:\t%x", HI);
		$display("LO:\t%x", LO);

	end

end

endmodule
