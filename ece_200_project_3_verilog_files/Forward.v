module Forward(

	//MODULE INPUT
	input       FLUSH,
	input       CLOCK,
	input       STALL,
	input       RESET,
	input [31:0] ALUResult_OUT,//connected
	//EXE/ME -> froward
	input [4:0] writeRDEXEMEM,//connected
	input 	    writeEnableEXEMEM,//connected

	//MEM/WB --> Froward
	input [4:0] writeRDMEMWB,//connected
  input       writeEnableMEMWB,//connected

	//ID --> Froward
	input AltPCEnable_IN,
	input [4:0] IDRegisterRS_IN,//connected
	input [4:0] IDRegisterRT_IN,//connected
	input [5:0] OpcodeID_IN,

	//MODULE OUTPUTS

  	//FOrward -->EXE
	  output [1:0] ForwardRS_OUT,// forward Rs
	  output [1:0] ForwardRT_OUT,// forward RT

 	 //Forward -->ID
	  output [1:0] ForwardRSbranch_out,//
	  output [1:0] ForwardRTbranch_out
);
//EXE hazard detection
always @(posedge CLOCK or negedge RESET) begin
	if((writeRDEXEMEM==IDRegisterRS_IN)&&((writeRDEXEMEM!=0) && writeEnableEXEMEM))begin
		assign ForwardRS_OUT =2'b10;
	end
	 else if ((writeRDMEMWB==IDRegisterRS_IN)&&((writeRDMEMWB!=0) &&writeEnableMEMWB) )  begin
		assign ForwardRS_OUT =2'b01;
	end
	else begin
     assign ForwardRS_OUT =2'b00;
	end
        end
always @(posedge CLOCK or negedge RESET) begin
	if((writeRDEXEMEM==IDRegisterRT_IN)&&((writeRDEXEMEM!=0) && writeEnableEXEMEM))begin
      assign ForwardRT_OUT =2'b10;
        end
	else if ((writeRDMEMWB==IDRegisterRT_IN)&&((writeRDMEMWB!=0) &&writeEnableMEMWB) )  begin
      assign ForwardRT_OUT =2'b01;
        end
	else begin
	 assign ForwardRT_OUT =2'b00;
	end
	end
//branching hazard detection
always @(posedge CLOCK or negedge RESET) begin
	if((OpcodeID_IN==1) ||(OpcodeID_IN==4)||(OpcodeID_IN==5)||(OpcodeID_IN==6) ||(OpcodeID_IN==7)) begin
	$display("AltPCEnable_IN %b", AltPCEnable_IN);
		if((writeRDEXEMEM==IDRegisterRS_IN)&&( (writeRDEXEMEM!=0)&&writeEnableEXEMEM))begin
		assign ForwardRSbranch_out=2'b10;
		end
		else begin
		assign ForwardRSbranch_out=2'b00;
		end
		if((writeRDEXEMEM==IDRegisterRT_IN)&&( (writeRDEXEMEM!=0)&&writeEnableEXEMEM))begin
   		 assign ForwardRTbranch_out=2'b10;
   		 end
		else begin
		assign ForwardRTbranch_out=2'b00;
		end
	end
end


endmodule
