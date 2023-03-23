module Hazard(

	//MODULE INPUTS

		//CONTROL SIGNALS
		input	CLOCK,
		input 	RESET,

		//ID --> Hazard
		input Jumb_IN,
		input Branch_IN,
		input  [4:0] IDRegisterRS_IN,
		input  [4:0] IDRegisterRT_IN,

		//ID/EXE --> Hazard
		input [4:0] IDEXEWriteRegister_IN,
		input IDEXEWriteEnable_IN,
		//EXE/MEM --> HAZARD
		input [4:0] EXEMEMWriteRegister_IN,
		input EXEMEMMemRead_IN,
	//MODULE OUTPUTS

		output 	STALL_IFID,
		output 	FLUSH_IFID,

		output 	STALL_IDEXE,
		output 	FLUSH_IDEXE,

		output 	STALL_EXEMEM,
		output 	FLUSH_EXEMEM,

		output 	STALL_MEMWB,
		output 	FLUSH_MEMWB

);

reg [4:0] MultiCycleRing;

assign FLUSH_MEMWB = 1'b0;
assign STALL_MEMWB = 1'b0;

assign FLUSH_EXEMEM = 1'b0;
assign STALL_EXEMEM = (FLUSH_MEMWB || STALL_MEMWB);

assign FLUSH_IDEXE = FLUSH_IDEXE_Enable;
assign STALL_IDEXE = (FLUSH_EXEMEM || STALL_EXEMEM);

assign FLUSH_IFID = !(MultiCycleRing[0]);
assign STALL_IFID = (FLUSH_IDEXE || STALL_IDEXE || FLUSH_IFID || STALL_IFID_Enable);
wire STALL_IFID_Enable;
wire FLUSH_IDEXE_Enable;
//when brnaches or jumbs are taken to stall for one cycle so the branch and its delay slot are excuted
always @(posedge CLOCK or negedge RESET) begin
	if(Jumb_IN || Branch_IN) begin
		assign STALL_IFID_Enable =1'b1;
	end
	else begin
``	assign STALL_IFID_Enable =1'b0;
	end
end
//Control hazard 1; Load hazard 
always @(posedge CLOCK or negedge RESET) begin
	if(((IDEXEWriteEnable_IN)&& ((Branch_IN || Jumb_IN)&&((IDRegisterRS_IN == IDEXEWriteRegister_IN)||(IDRegisterRT_IN == IDEXEWriteRegister_IN))))||((Branch_IN || Jumb_IN)&&EXEMEMMemRead_IN &&((EXEMEMWriteRegister_IN ==IDRegisterRS_IN) || (EXEMEMWriteRegister_IN ==IDRegisterRT_IN))))begin
		assign FLUSH_IDEXE_Enable= 1'b1;
	end
	else
		assign FLUSH_IDEXE_Enable= 1'b0;
end
always @(posedge CLOCK or negedge RESET) begin

	if(!RESET) begin

		MultiCycleRing <= 5'b11111;

	end else if(CLOCK) begin

		$display("");
		$display("----- HAZARD UNIT -----");
		$display("Multicycle Ring: %b", MultiCycleRing);

		MultiCycleRing <= {{MultiCycleRing[3:0],MultiCycleRing[4]}};

	end

end

endmodule
