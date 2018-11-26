`include<defines.v>

module ID(
    input wire clk,
    input wire rst,
    input wire [31:0] inst_i,
    input wire [31:0] pc_i,
    
    input wire [31:0] readData1_i,
    input wire [31:0] readData2_i,
    
    input wire [31:0] exceptionType_i,
    
    //data from HILO registers
    input wire [31:0] HI_data_i,
    input wire [31:0] LO_data_i,
    
    //data from CP0
	input wire [31:0] CP0_data_i,
	input wire [31:0] cause_i,

    
    //EX bypass signals  
    input wire [4:0] EX_writeAddr_i,
    input wire EX_writeEnable_i,
    input wire[1:0] EX_writeHILO_i,
    input wire [31:0] EX_writeHI_data_i,
    input wire [31:0] EX_writeLO_data_i,
    input wire EX_write_CP0_i,
    input wire [4:0] EX_write_CP0_addr_i,
    input wire next_in_delay_slot_i,
    
    //MEM bypass signals
    input wire [4:0] MEM_writeAddr_i,
    input wire MEM_writeEnable_i,
    input wire [1:0] MEM_writeHILO_i,
    input wire [31:0] MEM_writeHI_data_i,
    input wire [31:0] MEM_writeLO_data_i,
    input wire MEM_write_CP0_i,
    input wire [4:0] MEM_write_CP0_addr_i,
    
    //about the load conflict
    input wire [3:0] EX_ramOp_i,
    
    output reg [4:0] readAddr1_o,
    output reg [4:0] readAddr2_o,
    output reg readEnable1_o,
    output reg readEnable2_o,
    output reg [4:0] writeAddr_o,
    output reg writeEnable_o,
    
    output reg [1:0] writeHILO_o,
    
    output reg [31:0] oprand1_o,
    output reg [31:0] oprand2_o,
    output reg branchEnable_o,
    output reg [31:0] branchAddr_o,
    output reg [4:0] ALUop_o,
    output reg signed_o,
    
    output reg write_CP0_o,
	output reg [4:0] write_CP0_addr_o,
	output reg [4:0] read_CP0_addr_o,
    
    output wire [31:0] inst_o,
    output wire [31:0] pc_o,
    output reg in_delay_slot_o,
    output reg next_in_delay_slot_o,
    output wire [31:0] exceptionType_o,
    output reg pauseRequest
);
	assign inst_o = inst_i;
	assign pc_o = pc_i;
	
    wire [5:0] inst_op = inst_i[31:26];
    wire [4:0] inst_rs = inst_i[25:21];
    wire [4:0] inst_rt = inst_i[20:16];
    wire [4:0] inst_rd = inst_i[15:11];
    wire [4:0] inst_shamt = inst_i[10:6];
    wire [5:0] inst_func = inst_i[5:0];
    
    reg [1:0] readHILO;
    reg [31:0] imm;
    reg read_CP0;
    
    wire load_conflict;
    wire [31:0] pc_plus_4, pc_plus_8;
    
    assign pc_plus_4 = pc_i + 32'h4;
    assign pc_plus_8 = pc_i + 32'h8;
    
    reg syscall;
	reg eret;
	reg instInvalid;
	reg break;
	reg tlbwi;
	reg tlbwr;
	assign exceptionType_o = {exceptionType_i[31:15], tlbwr, tlbwi, eret, 1'b0, break, instInvalid, syscall, 8'b0};
    
    //get the stall request 
    assign load_conflict = (EX_ramOp_i == `MEM_LW) || 
    					   (EX_ramOp_i == `MEM_LB) || 
    					   (EX_ramOp_i == `MEM_LH) || 
    					   (EX_ramOp_i == `MEM_LBU) || 
    					   (EX_ramOp_i == `MEM_LHU);
    always @(*) begin
    	if(rst == 1'b1) begin
    		pauseRequest <= 1'b0;
    	end else begin
    		if(EX_writeAddr_i == readAddr1_o && readEnable1_o == 1'b1 || 
    		   EX_writeAddr_i == readAddr2_o && readEnable2_o == 1'b1) begin
    			pauseRequest <= load_conflict;
    		end else begin
    			pauseRequest <= 1'b0;
    		end
    	end
    end
    								
    
    //get the first operand
    always @ (*) begin
    	if (rst == 1'b1) begin
    		oprand1_o <= 32'b0;
    	end else if(read_CP0 == 1'b1 && EX_write_CP0_i == 1'b1 && EX_write_CP0_addr_i == read_CP0_addr_o) begin
			if(read_CP0_addr_o == `CAUSE) begin
				oprand1_o <= {cause_i[31:24], EX_writeLO_data_i[23:22], cause_i[21:10], EX_writeLO_data_i[9:8], cause_i[7:0]};//cause register is partly writable
			end else begin 
				oprand1_o <= EX_writeLO_data_i;
			end
    	end else if(read_CP0 == 1'b1 && MEM_write_CP0_i == 1'b1 && MEM_write_CP0_addr_i == read_CP0_addr_o) begin
			if(read_CP0_addr_o == `CAUSE) begin
				oprand1_o <= {cause_i[31:24], MEM_writeLO_data_i[23:22], cause_i[21:10], MEM_writeLO_data_i[9:8], cause_i[7:0]};//cause register is partly writable
			end else begin 
				oprand1_o <= MEM_writeLO_data_i;
			end
		end else if(read_CP0 == 1'b1) begin
			oprand1_o <= CP0_data_i;
		end else if(readHILO == 2'b10 && EX_writeHILO_i[1] == 1'b1) begin
    		oprand1_o <= EX_writeHI_data_i;
    	end else if(readHILO == 2'b01 && EX_writeHILO_i[0] == 1'b1) begin
    		oprand1_o <= EX_writeLO_data_i;
    	end else if(readHILO == 2'b10 && MEM_writeHILO_i[1] == 1'b1) begin
    		oprand1_o <= MEM_writeHI_data_i;
    	end else if(readHILO == 2'b01 && MEM_writeHILO_i[0] == 1'b1) begin
    		oprand1_o <= MEM_writeLO_data_i;
    	end else if(readHILO == 2'b10) begin
    		oprand1_o <= HI_data_i;
    	end else if(readHILO == 2'b01) begin
    		oprand1_o <= LO_data_i;	
    	end else if(readEnable1_o == 1'b1 && EX_writeEnable_i == 1'b1 &&
    				EX_writeAddr_i == readAddr1_o) begin
    		oprand1_o <= EX_writeLO_data_i;
  		end else if(readEnable1_o == 1'b1 && MEM_writeEnable_i == 1'b1 &&
  					MEM_writeAddr_i == readAddr1_o) begin
  			oprand1_o <= MEM_writeLO_data_i;
  		end else if(readEnable1_o == 1'b1) begin
  			oprand1_o <= readData1_i;
  		end else if(readEnable1_o == 1'b0) begin
  			oprand1_o <= imm;
  		end else begin
  			oprand1_o <= 32'b0;
  		end
  	end
  	
  	//get the second oprand
  	always @ (*) begin
		if (rst == 1'b1) begin
			oprand2_o <= 32'b0;
		end else if(readEnable2_o == 1'b1 && EX_writeEnable_i == 1'b1 &&
					EX_writeAddr_i == readAddr2_o) begin
			oprand2_o <= EX_writeLO_data_i;
		end else if(readEnable2_o == 1'b1 && MEM_writeEnable_i == 1'b1 &&
					MEM_writeAddr_i == readAddr2_o) begin
			oprand2_o <= MEM_writeLO_data_i;
		end else if(readEnable2_o == 1'b1) begin
			oprand2_o <= readData2_i;
		end else if(readEnable2_o == 1'b0) begin
			oprand2_o <= imm;
		end else begin
			oprand2_o <= 32'b0;
		end
	end
    	
    //decode the instructions	
    always @ (*) begin
        if(rst == 1'b1) begin
            readAddr1_o <= 5'b0;
            readAddr2_o <= 5'b0;
            readEnable1_o <= 1'b0;
            readEnable2_o <= 1'b0;
            readHILO <= 2'b00;
            imm <= 32'b0;
            writeAddr_o <= 4'b0;
            writeEnable_o <= 1'b0;
            branchEnable_o <= 1'b0;
            branchAddr_o <= 32'b0;
            writeHILO_o <= 2'b00;
            ALUop_o <= `ALU_NOP;
            signed_o <= 1'b0;
            next_in_delay_slot_o <= 1'b0;
            in_delay_slot_o <= 1'b0;
            syscall <= 1'b0;
			eret <= 1'b0;
			instInvalid <= 1'b0;
			break <= 1'b0;
			tlbwi <= 1'b0;
			tlbwr <= 1'b0;
			write_CP0_o <= 1'b0;
			write_CP0_addr_o <= 5'b0;
			read_CP0_addr_o <= 4'b0;
			read_CP0 <= 1'b0;
            
         end else begin
         	//assign the default values
			readAddr1_o <= 5'b0;
			readAddr2_o <= 5'b0;
			readEnable1_o <= 1'b0;
			readEnable2_o <= 1'b0;
			readHILO <= 2'b00;
			imm <= 32'b0;
			writeAddr_o <= 5'b0;
			writeEnable_o <= 1'b0;
			branchEnable_o <= 1'b0;
			branchAddr_o <= 32'b0;
			ALUop_o <= `ALU_NOP;
			writeHILO_o <= 2'b00;
			signed_o <= 1'b0;
			next_in_delay_slot_o <= 1'b0;
			in_delay_slot_o <= next_in_delay_slot_i;
			syscall <= 1'b0;
			eret <= 1'b0;
			break <= 1'b0;
			instInvalid <= 1'b1;
			tlbwi <= 1'b0;
			tlbwr <= 1'b0;
			write_CP0_o <= 1'b0;
			write_CP0_addr_o <= 5'b0;	
			read_CP0_addr_o <= 4'b0;
			read_CP0 <= 1'b0;		            
			
          	case (inst_op)
                
                /**********load/store instructions***********/
                `OP_SW: begin
                	readEnable1_o <= 1'b1;
                	readAddr1_o <= inst_rs;
                	readEnable2_o <= 1'b1;
                	readAddr2_o <= inst_rt;
                	ALUop_o <= `ALU_SW;	
                	instInvalid <= 1'b0;
                end
                
                `OP_SB: begin
                	readEnable1_o <= 1'b1;
                	readAddr1_o <= inst_rs;
                	readEnable2_o <= 1'b1;
                	readAddr2_o <= inst_rt;
                	ALUop_o <= `ALU_SB;
                	instInvalid <= 1'b0;
                end
                
                `OP_SH: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					readEnable2_o <= 1'b1;
					readAddr2_o <= inst_rt;
					ALUop_o <= `ALU_SH;
					instInvalid <= 1'b0;
				end
                
                `OP_LW: begin
                	readEnable1_o <= 1'b1;
                	readAddr1_o <= inst_rs;
                	writeEnable_o <= 1'b1;
                	writeAddr_o <= inst_rt;
                	imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                	ALUop_o <= `ALU_LW;
                	instInvalid <= 1'b0;
                end
                
                `OP_LB: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_LB;
					instInvalid <= 1'b0;
				end
				
				`OP_LH: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_LH;
					instInvalid <= 1'b0;
				end
				
				`OP_LBU: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_LBU;
					instInvalid <= 1'b0;
				end
								
				`OP_LHU: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_LHU;
					instInvalid <= 1'b0;
				end
                /**********load/store end*********/
                
                `OP_ADDI: begin
                	readEnable1_o <= 1'b1;
                	readAddr1_o <= inst_rs;
                	writeEnable_o <= 1'b1;
                	writeAddr_o <= inst_rt;
                	imm <= {{16{inst_i[15]}}, inst_i[15:0]};
                	signed_o <= 1'b1;
                	ALUop_o <= `ALU_ADD;
                	instInvalid <= 1'b0;
                end
                
                `OP_ADDIU: begin
                	readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_ADD;
					instInvalid <= 1'b0;
				end
				
				`OP_SLTI: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					signed_o <= 1'b1;
					ALUop_o <= `ALU_SLT;
					instInvalid <= 1'b0;
				end
				
				`OP_SLTIU: begin
					
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					ALUop_o <= `ALU_SLT;
					instInvalid <= 1'b0;
					
				end
				
				`OP_ANDI: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					imm <= {16'b0, inst_i[15:0]};
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					ALUop_o <= `ALU_AND;
					instInvalid <= 1'b0;
				end
				
				
                `OP_ORI: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					imm <= {16'b0, inst_i[15:0]};
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					ALUop_o <= `ALU_OR;
					instInvalid <= 1'b0;	
				end
				
				`OP_XORI: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					imm <= {16'b0, inst_i[15:0]};
					writeEnable_o <= 1'b1;
					writeAddr_o <= inst_rt;
					ALUop_o <= `ALU_XOR;	
					instInvalid <= 1'b0;
				end
				
				
				`OP_LUI: begin
					if(inst_rs == 5'b0) begin
						imm <= {inst_i[15:0], 16'b0};
						writeEnable_o <= 1'b1;
						writeAddr_o <= inst_rt;
						ALUop_o <= `ALU_MOV;
						instInvalid <= 1'b0;
					end
				end
					
				`OP_J: begin
    				branchEnable_o <= 1'b1;
    				branchAddr_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b0};
    				next_in_delay_slot_o <= 1'b1;
    				instInvalid <= 1'b0;
    			end
    			
    			`OP_JAL: begin
    				branchEnable_o <= 1'b1;
					writeEnable_o <= 1'b1;
					writeAddr_o <= 5'd31;
					ALUop_o <= `ALU_BAJ;
					imm <= pc_plus_8;
    				branchAddr_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b0};
    				next_in_delay_slot_o <= 1'b1;
    				instInvalid <= 1'b0;
    			end
    			
    			`OP_BEQ: begin
    				readEnable1_o <= 1'b1;
    				readAddr1_o <= inst_rs;
    				readEnable2_o <= 1'b1;
    				readAddr2_o <= inst_rt;
    				next_in_delay_slot_o <= 1'b1;
    				instInvalid <= 1'b0;
    				
    				if(oprand1_o == oprand2_o) begin
    					branchEnable_o <= 1'b1;
    					branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
    				end else begin
    					branchEnable_o <= 1'b0;
    				end
    			end
    			
    			`OP_BNE: begin
					readEnable1_o <= 1'b1;
					readAddr1_o <= inst_rs;
					readEnable2_o <= 1'b1;
					readAddr2_o <= inst_rt;
					next_in_delay_slot_o <= 1'b1;
					instInvalid <= 1'b0;
					
					if(oprand1_o != oprand2_o) begin
						branchEnable_o <= 1'b1;
						branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
					end else begin
						branchEnable_o <= 1'b0;
					end
				end
    			
    			`OP_BLEZ: begin
    				if(inst_rt == 5'b0) begin
						readEnable1_o <= 1'b1;
						readAddr1_o <= inst_rs;
						next_in_delay_slot_o <= 1'b1;
						instInvalid <= 1'b0;
						
						if(oprand1_o[31] == 1'b1 || oprand1_o == 32'b0) begin
							branchEnable_o <= 1'b1;
							branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
						end else begin
							branchEnable_o <= 1'b0;
						end
					end
				end
    			
    			`OP_BGTZ: begin
    				if(inst_rt == 5'b0) begin
						readEnable1_o <= 1'b1;
						readAddr1_o <= inst_rs;
						next_in_delay_slot_o <= 1'b1;
						instInvalid <= 1'b0;
					
						if(oprand1_o[31] != 1'b1 && oprand1_o != 32'b0) begin
							branchEnable_o <= 1'b1;
							branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
						end else begin
							branchEnable_o <= 1'b0;
						end
					end else begin
						instInvalid <= 1'b1;
					end
				end
                				
            	`OP_SPECIAL: begin
            		case(inst_func)
            			`FUNC_ADD: begin
            				if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								signed_o <= 1'b1;
								ALUop_o <= `ALU_ADD;
								instInvalid <= 1'b0;
            				end
            			end
            			
            			`FUNC_ADDU: begin
            				if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_ADD;
								instInvalid <= 1'b0;
							end
						end
						
						`FUNC_SUB: begin
							if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								signed_o <= 1'b1;
								ALUop_o <= `ALU_SUB;
								instInvalid <= 1'b0;
							end
						end
            			
            			`FUNC_SUBU: begin
            				if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_SUB;
								instInvalid <= 1'b0;
							end
						end
						
						`FUNC_AND: begin
							if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_AND;
								instInvalid <= 1'b0;
							end
						end
						
						`FUNC_OR: begin
							if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_OR;
								instInvalid <= 1'b0;
							end
						end
						
						`FUNC_XOR: begin
							if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_XOR;
								instInvalid <= 1'b0;
							end
						end	

						`FUNC_NOR: begin
							if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_NOR;
								instInvalid <= 1'b0;
							end
						end	
						
						`FUNC_SLT: begin
							if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								signed_o <= 1'b1;
								ALUop_o <= `ALU_SLT;
								instInvalid <= 1'b0;
							end
						end	

						`FUNC_SLTU: begin
							if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_SLT;
								instInvalid <= 1'b0;
							end
						end	

						`FUNC_SLL: begin
							if(inst_rs == 5'b0)	begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rt;
								imm <= inst_shamt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_SLL;
								instInvalid <= 1'b0;
							end
						end

						`FUNC_SRL: begin
							if(inst_rs == 5'b0)	begin	
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rt;
								imm <= inst_shamt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_SRL;
								instInvalid <= 1'b0;
							end
						end

						`FUNC_SRA: begin	
							if(inst_rs == 5'b0)	begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rt;
								imm <= inst_shamt;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_SRA;
								instInvalid <= 1'b0;
							end
						end

						`FUNC_SLLV: begin	
							if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rt;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rs;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_SLL;
								instInvalid <= 1'b0;
							end
						end

						`FUNC_SRLV: begin	
							if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rt;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rs;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_SRL;
								instInvalid <= 1'b0;
							end
						end

						`FUNC_SRAV: begin	
							if(inst_shamt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rt;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rs;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_SRA;
								instInvalid <= 1'b0;
							end
						end

						`FUNC_MULT: begin
							if(inst_i[15:6] == 10'b0) begin
								writeHILO_o <= 2'b11;
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								signed_o <= 1'b1;
								ALUop_o <= `ALU_MULT;
								instInvalid <= 1'b0;
							end
            			end

						`FUNC_MULTU: begin
							if(inst_i[15:6] == 10'b0) begin
								writeHILO_o <= 2'b11;
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								ALUop_o <= `ALU_MULT;
								instInvalid <= 1'b0;
							end
            			end

						`FUNC_DIV: begin
							if(inst_i[15:6] == 10'b0) begin
								writeHILO_o <= 2'b11;
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								signed_o <= 1'b1;
								ALUop_o <= `ALU_DIV;
								instInvalid <= 1'b0;
							end
            			end

						`FUNC_DIVU: begin
							if(inst_i[15:6] == 10'b0) begin
								writeHILO_o <= 2'b11;
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								readEnable2_o <= 1'b1;
								readAddr2_o <= inst_rt;
								ALUop_o <= `ALU_DIV;
								instInvalid <= 1'b0;
							end
            			end

            			`FUNC_MFHI: begin
							if(inst_i[25:16] == 10'b0 && inst_shamt == 5'b0) begin
								readHILO <= 2'b10;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_MOV;
								instInvalid <= 1'b0;
							end
            			end
            			
            			`FUNC_MTHI: begin
							if(inst_i[20:6] == 15'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								writeHILO_o <= 2'b10;
								ALUop_o <= `ALU_MOV;
								instInvalid <= 1'b0;
							end
            			end
            			
            			`FUNC_MFLO: begin
							if(inst_i[25:16] == 10'b0 && inst_shamt == 5'b0) begin
								readHILO <= 2'b01;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								ALUop_o <= `ALU_MOV;
								instInvalid <= 1'b0;
							end
            			end
            			
            			`FUNC_MTLO: begin
							if(inst_i[20:6] == 15'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								writeHILO_o <= 2'b01;
								ALUop_o <= `ALU_MOV;
								instInvalid <= 1'b0;
							end
            			end

						`FUNC_JR: begin
							if(inst_i[20:11] == 10'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								branchEnable_o <= 1'b1;
								branchAddr_o <= oprand1_o;
								next_in_delay_slot_o <= 1'b1;
								instInvalid <= 1'b0;
							end
						end
						
						`FUNC_JALR: begin
							if(inst_rt == 5'b0) begin
								readEnable1_o <= 1'b1;
								readAddr1_o <= inst_rs;
								writeEnable_o <= 1'b1;
								writeAddr_o <= inst_rd;
								imm <= pc_plus_8;
								ALUop_o <= `ALU_BAJ;
								next_in_delay_slot_o <= 1'b1;
								instInvalid <= 1'b0;
								
								branchEnable_o <= 1'b1;
								branchAddr_o <= oprand1_o;
							end
						end
						
						`FUNC_SYSCALL: begin
							syscall <= 1'b1;
							instInvalid <= 1'b0;
						end
						
						`FUNC_BREAK: begin
							break <= 1'b1;
							instInvalid <= 1'b0;
						end
						
						default: begin
							instInvalid <= 1'b1;
						end
            		endcase
            	end

				`OP_REGIMM: begin
					case(inst_rt) 
						`RT_BLTZ: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							next_in_delay_slot_o <= 1'b1;
							instInvalid <= 1'b0;
							
							if(oprand1_o[31] == 1'b1) begin
								branchEnable_o <= 1'b1;
								branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
							end else begin
								branchEnable_o <= 1'b0;
							end
						end
						
						`RT_BGEZ: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							next_in_delay_slot_o <= 1'b1;
							instInvalid <= 1'b0;
							
							if(oprand1_o[31] == 1'b0) begin
								branchEnable_o <= 1'b1;
								branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
							end else begin
								branchEnable_o <= 1'b0;
							end
						end
						
						`RT_BLTZAL: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							writeEnable_o <= 1'b1;
							writeAddr_o <= 5'd31;
							imm <= pc_plus_8;
							ALUop_o <= `ALU_BAJ;
							next_in_delay_slot_o <= 1'b1;
							instInvalid <= 1'b0;
							
							if(oprand1_o[31] == 1) begin
								branchEnable_o <= 1'b1;
								branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
							end else begin
								branchEnable_o <= 1'b0;
							end
						end
						
						`RT_BGEZAL: begin
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rs;
							writeEnable_o <= 1'b1;
							writeAddr_o <= 5'd31;
							imm <= pc_plus_8;
							ALUop_o <= `ALU_BAJ;
							next_in_delay_slot_o <= 1'b1;
							instInvalid <= 1'b0;
							
							if(oprand1_o[31] == 0) begin
								branchEnable_o <= 1'b1;
								branchAddr_o <= pc_plus_4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b0};
							end else begin
								branchEnable_o <= 1'b0;
							end
						end
						
						default: begin
							instInvalid <= 1'b1;
						end
					endcase
				end
				
				`OP_COP0: begin
					
					if(inst_rs == `RS_MTC0) begin
						if(inst_i[10:3] == 8'b0) begin
							write_CP0_o <= 1'b1;
							write_CP0_addr_o <= inst_rd;
							readEnable1_o <= 1'b1;
							readAddr1_o <= inst_rt;
							ALUop_o <= `ALU_MOV;
							instInvalid <= 1'b0;
						end
					end else if(inst_rs == `RS_MFC0) begin
						if(inst_i[10:3] == 8'b0) begin
							writeEnable_o <= 1'b1;
							writeAddr_o <= inst_rt;
							read_CP0 <= 1'b1;
							read_CP0_addr_o <= inst_rd;
							ALUop_o <= `ALU_MOV;
							instInvalid <= 1'b0;
						end
					end else if(inst_i[25] == 1'b1 && inst_func == `FUNC_ERET) begin
						if(inst_i[24:6] == 19'b0) begin
							eret <= 1'b1;
							instInvalid <= 1'b0;
						end
					end else if(inst_i[25] == 1'b1 && inst_i[24:6] == 19'b0 &&
								inst_func == `FUNC_TLBWI) begin
							tlbwi <= 1'b1;
							instInvalid <= 1'b0;
					end else if(inst_i[25] == 1'b1 && inst_i[24:6] == 19'b0 &&
								inst_func == `FUNC_TLBWR) begin
							tlbwr <= 1'b1;
							instInvalid <= 1'b0;
					end else begin
						instInvalid <= 1'b1;
					end
				end
			
			default: begin
				instInvalid <= 1'b1;
			end
            endcase
        end
    end
endmodule
      