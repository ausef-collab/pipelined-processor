module Compare(

	//MODULE INPUTS
		input 		CLOCK,
		input		RESET,
		input 		Jump_IN,
		input [5:0]	Opcode_IN,
	        input [4:0]	RegisterRT_IN,
		input [31:0] 	OperandA_IN,
		input [31:0] 	OperandB_IN,
		input [1:0] 	ForwardRSbranch_IN,//connected
		input [1:0] 	ForwardRTbranch_IN,//connected
		input [31:0] 	ALUResult_IN,

	//MODULE OUTPUTS

		output Taken_OUT

);
wire [31:0] OperandA_NEW;
wire [31:0] OperandB_NEW;
wire        BranchTaken;

//what this is doing is fixing the vaules of the operands A & B by forwarding vaules from ALUResult_IN
always @(posedge CLOCK or negedge RESET) begin
	if(ForwardRSbranch_IN == 2'b10)begin
		assign OperandA_NEW = ALUResult_IN;
		$display("forward (RS) pass from EXEMEM to ID ,\nforwarded value: %d\n old vaule:%d ", OperandA_NEW,OperandA_IN);
	end
	else begin
		assign OperandA_NEW =OperandA_IN;
		$display("No forwarding needed\n");
	end
end

always @(posedge CLOCK or negedge RESET) begin
	if(ForwardRTbranch_IN==2'b10)begin
		assign OperandB_NEW =ALUResult_IN;
		$display("forward (RT) pass from EXEMEM, %d\n old vaule:%d ", OperandB_NEW,OperandB_IN);
	end
	else begin
		assign OperandB_NEW =OperandB_IN;
		$display("No forwarding needed\n");
	end
end



assign 	Taken_OUT = BranchTaken | Jump_IN;


/* TODO
 * Procedural assignment to wires is not in standard
 * Need to find a better way to represent this
 * Preventing using higher versions of verilator
 */
always begin

	//CASE STATEMENT FOR OPCODE
	case(Opcode_IN)

		//OPCODE: 1 (REGIMM)
		6'b000001:begin

			//CASE STATEMENT FOR RT
			case(RegisterRT_IN)

				//RT: 0, 16 (BLTZ, BTZAL)
				5'b00000,5'b10000:begin

					//BRANCH IS TAKEN IF OPERAND A IS NEGATIVE
					BranchTaken = (OperandA_NEW[31] == 1) ? 1'b1 : 1'b0;

				end

				//RT: 1, 17 (BGEZ, BGEZAL)
				5'b00001,5'b10001:begin

					//BRANCH IS TAKEN IF OPERAND A IS POSITIVE OR ZERO
					BranchTaken = (OperandA_NEW[31] == 0) ? 1'b1 : 1'b0;

				end

				//RT: NOT A BRANCH INSTRUCTION
				default:begin

					//BRANCH IS NOT TAKEN
					BranchTaken = 1'b0;

				end

			endcase
		end

		//OPCODE: 4 (BEQ)
		6'b000100:begin

			//BRANCH IS TAKEN IF OPERAND A AND OPERAND B ARE EQUAL
			BranchTaken = (OperandA_NEW == OperandB_NEW) ? 1'b1 : 1'b0;

		end

		//OPCODE: 5 (BNE)
		6'b000101:begin

			//BRANCH IS TAKEN IF OPERAND A AND OPERAND B ARE NOT EQUAL
			BranchTaken = (OperandA_NEW != OperandB_NEW) ? 1'b1 : 1'b0;

		end

		//OPCODE: 6 (BLEZ)
		6'b000110:begin

			//BRANCH IS TAKEN IF OPERAND A IS NEGATIVE OR ZERO
			BranchTaken = ((OperandA_NEW[31] == 1) || (OperandA_NEW == 0)) ? 1'b1 : 1'b0;

		end

		//OPCODE: 7 (BGTZ)
		6'b000111: begin

			//BRANCH IS TAKEN IF OPERAND A IS POSITIVE AND NOT ZERO
			BranchTaken = ((OperandA_NEW[31] == 0) && (OperandA_NEW != 0)) ? 1'b1 : 1'b0;

		end

		//OPCODE: NOT A BRANCH INSTRUCTION
		default: begin

			//BRANCH IS NOT TAKEN
			BranchTaken = 1'b0;

		end

	endcase

end

endmodule
