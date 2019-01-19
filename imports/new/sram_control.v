`include<defines.v>

module sram_control (
	input wire clk,
	input wire rst,
	input wire [19:0] dataAddr_i,
	input wire [19:0] instAddr_i,
	input wire [31:0] storeData_i,
	input wire [3:0] ramOp_i,
	input wire [1:0] bytes_i,
	
	input wire [3:0] EX_ramOp_i,
	input wire [31:0] EX_ramAddr_i,
	input wire EX_tlbmiss_i,
	
	output reg [31:0] loadInst_o,
	output reg [31:0] loadData_o,
	output reg base_we_n_o, base_ce_n_o, base_oe_n_o,
	output reg [3:0] base_be_n_o,
	output reg ext_we_n_o, ext_ce_n_o, ext_oe_n_o,
	output reg [3:0] ext_be_n_o,
	output reg [19:0] instAddr_o,
	output reg [19:0] dataAddr_o,
	output reg pauseRequest,
	
	inout wire [31:0] inst_io,
	inout wire [31:0] data_io
);
	

	wire write, load;
	wire base_read, base_write, ext_read, ext_write;
	wire base, ext;
	wire addressError;
	assign addressError = (EX_ramOp_i == `MEM_LW) && (EX_ramAddr_i[1:0] != 2'b0) ||
						  (EX_ramOp_i == `MEM_LH) && (EX_ramAddr_i[0] != 1'b0) ||
						  (EX_ramOp_i == `MEM_LHU) && (EX_ramAddr_i[0] != 1'b0) ||
						  (EX_ramOp_i == `MEM_SW) && (EX_ramAddr_i[1:0] != 2'b0) ||
						  (EX_ramOp_i == `MEM_SH) && (EX_ramAddr_i[0] != 1'b0);
	
	assign write = ((EX_ramOp_i == `MEM_SW || EX_ramOp_i == `MEM_SH || EX_ramOp_i == `MEM_SB) && addressError == 1'b0 && EX_tlbmiss_i == 1'b0 && EX_ramAddr_i[31:8] != 32'hBFD003F) ? 1'b1 : 1'b0;
	assign load = (write == 0 && EX_ramOp_i != `MEM_NOP && addressError == 1'b0 && EX_tlbmiss_i == 1'b0 && EX_ramAddr_i[31:8] != 32'hBFD003F) ? 1'b1 : 1'b0;
	assign base = (EX_ramAddr_i < 32'h80400000) && (EX_ramAddr_i >= 32'h80000000) || EX_ramAddr_i < 32'h00300000;
	//assign base = 1'b0;
	assign ext = ~base;
	assign base_read = load && base;
	assign base_write = write && base; 
	assign ext_read = load && ext;
	assign ext_write = write && ext;
	
	
	reg [2:0] state, nstate, pstate;	
	reg [31:0] loadData_reg;
	parameter IDLE = 4'd0, 				//instruction fetch
			  WRITE_BASE = 4'd1,
			  WRITE_BASE_HOLD = 4'd2,
			  READ_BASE = 4'd3,
			  WRITE_EXT = 4'd4,
			  WRITE_EXT_HOLD = 4'd5,
			  READ_EXT = 4'd6,
			  READ_BASE_END = 4'd7;
			  
	assign data_io = (ramOp_i == `MEM_SW) ? storeData_i : ((ramOp_i == `MEM_SH) ? {2{storeData_i[15:0]}} : ((ramOp_i == `MEM_SB) ? {4{storeData_i[7:0]}} : 32'bz));
	assign inst_io = (state != WRITE_BASE && state != WRITE_BASE_HOLD) ? 32'bz : ((ramOp_i == `MEM_SW) ? storeData_i : ((ramOp_i == `MEM_SH) ? {2{storeData_i[15:0]}} : ((ramOp_i == `MEM_SB) ? {4{storeData_i[7:0]}} : 32'bz)));
		  
	always @(posedge clk) begin
		if(rst == 1'b1) begin
			state <= IDLE;
			pstate <= IDLE;
			loadData_reg <= 32'b0;
		end else begin
			state <= nstate;
			pstate <= state;
			if(state == READ_BASE) begin
				loadData_reg <= loadData_o;
			end
		end
	end
		
    always @(*) begin
    	if(rst == 1'b1) begin
			base_we_n_o <= 1'b1;
			base_ce_n_o <= 1'b0;
			base_oe_n_o <= 1'b0;
			base_be_n_o <= 4'b0000;
			ext_we_n_o <= 1'b1;
			ext_ce_n_o <= 1'b1;
			ext_oe_n_o <= 1'b1;
			ext_be_n_o <= 4'b1111;
			instAddr_o <= instAddr_i;
			dataAddr_o <= 20'b0;
			loadData_o <= 32'b0;
			loadInst_o <= inst_io;
			pauseRequest <= 1'b0;
			nstate <= IDLE;
		end else begin
			case(state) 
				IDLE: begin
					base_we_n_o <= 1'b1;
					base_ce_n_o <= 1'b0;
					base_oe_n_o <= 1'b0;
					base_be_n_o <= 4'b0000;
					ext_we_n_o <= 1'b1;
					ext_ce_n_o <= 1'b1;
					ext_oe_n_o <= 1'b1;
					ext_be_n_o <= 4'b1111;
					instAddr_o <= instAddr_i;
					dataAddr_o <= 20'b0;
					loadInst_o <= inst_io;
					
					if(pstate == READ_BASE) begin
						loadData_o <= loadData_reg;
					end else begin
						loadData_o <= 32'b0;
					end
					
					pauseRequest <= 1'b0;
					
					if(base_read == 1'b1) begin
						nstate <= READ_BASE;
					end else if(base_write == 1'b1) begin
						nstate <= WRITE_BASE;
					end else if(ext_read == 1'b1) begin
						nstate <= READ_EXT;
					end else if(ext_write == 1'b1) begin
						nstate <= WRITE_EXT;
					end else begin
						nstate <= IDLE;
					end
				end
				
				
				READ_EXT: begin
                    base_we_n_o <= 1'b1;
					base_ce_n_o <= 1'b0;
					base_oe_n_o <= 1'b0;
					base_be_n_o <= 4'b0000;
					ext_we_n_o <= 1'b1;
					ext_ce_n_o <= 1'b0;
					ext_oe_n_o <= 1'b0;
					ext_be_n_o <= 4'b0000;
					instAddr_o <= instAddr_i;
					dataAddr_o <= dataAddr_i;
					loadInst_o <= inst_io;
					loadData_o <= data_io;
					pauseRequest <= 1'b0;      
					      
                    case(ramOp_i) 
                        `MEM_LB: begin
                        	if(bytes_i == 2'b00) begin
                            	loadData_o <= {{24{data_io[7]}}, data_io[7:0]};
                            end else if(bytes_i == 2'b01) begin
                            	loadData_o <= {{24{data_io[15]}}, data_io[15:8]};
                            end else if(bytes_i == 2'b10) begin
                            	loadData_o <= {{24{data_io[23]}}, data_io[23:16]};
                            end else begin
                            	loadData_o <= {{24{data_io[31]}}, data_io[31:24]};
                            end
                        end
                        
                        `MEM_LBU: begin
                            if(bytes_i == 2'b00) begin
								loadData_o <= {24'b0, data_io[7:0]};
							end else if(bytes_i == 2'b01) begin
								loadData_o <= {24'b0, data_io[15:8]};
							end else if(bytes_i == 2'b10) begin
								loadData_o <= {24'b0, data_io[23:16]};
							end else begin
								loadData_o <= {24'b0, data_io[31:24]};
							end
                        end
                                                
                        `MEM_LH: begin
                        	if(bytes_i == 2'b00) begin
                            	loadData_o <= {{16{data_io[15]}}, data_io[15:0]};
                            end else begin
                            	loadData_o <= {{16{data_io[31]}}, data_io[31:16]};
                            end
                        end
                        
                        `MEM_LHU: begin
                            if(bytes_i == 2'b00) begin
								loadData_o <= {16'b0, data_io[15:0]};
							end else begin
								loadData_o <= {16'b0, data_io[31:16]};
							end
                        end
                        
                        default: begin
                            loadData_o <= data_io;
                        end
                    endcase
                    
                    if(base_read == 1'b1) begin
                    	nstate <= READ_BASE;
                    end else if(base_write == 1'b1) begin
                    	nstate <= WRITE_BASE;
                    end else if(ext_read == 1'b1) begin
                    	nstate <= READ_EXT;
                    end else if(ext_write == 1'b1) begin
                    	nstate <= WRITE_EXT;
                    end else begin
                    	nstate <= IDLE;
                    end
                end
				
				
				WRITE_EXT: begin
					base_we_n_o <= 1'b1;
					base_ce_n_o <= 1'b0;
					base_oe_n_o <= 1'b0;
					base_be_n_o <= 4'b0000;
					ext_we_n_o <= 1'b0;
					ext_ce_n_o <= 1'b0;
					ext_oe_n_o <= 1'b1;
					ext_be_n_o <= 4'b0000;
					instAddr_o <= instAddr_i;
					dataAddr_o <= dataAddr_i;
					loadInst_o <= inst_io;
					loadData_o <= 20'b0;
					pauseRequest <= 1'b1;
				    
				    case(ramOp_i)
                        `MEM_SW: begin
                            ext_be_n_o <= 4'b0000;
                        end

                        `MEM_SH: begin
                        	if(bytes_i == 2'b00) begin
                            	ext_be_n_o <= 4'b1100;
                            end else if(bytes_i == 2'b10) begin
                            	ext_be_n_o <= 4'b0011;
                            end else begin
                            	ext_be_n_o <= 4'b1111;
                            end
                        end

                        `MEM_SB: begin
                        	if(bytes_i == 2'b00) begin
                            	ext_be_n_o <= 4'b1110;
                            end else if(bytes_i == 2'b01) begin
                            	ext_be_n_o <= 4'b1101;
                            end else if(bytes_i == 2'b10) begin
                            	ext_be_n_o <= 4'b1011;
                            end else begin
                            	ext_be_n_o <= 4'b0111;
                            end
                        end
                        
                        default: begin
                            ext_be_n_o <= 4'b1111;
                        end
                    endcase
                    
				    nstate <= WRITE_EXT_HOLD;
				    
				end
				
				WRITE_EXT_HOLD: begin
				    base_we_n_o <= 1'b1;
					base_ce_n_o <= 1'b0;
					base_oe_n_o <= 1'b0;
					base_be_n_o <= 4'b0000;
					ext_we_n_o <= 1'b1;
					ext_ce_n_o <= 1'b0;
					ext_oe_n_o <= 1'b1;
					ext_be_n_o <= 4'b0000;
					instAddr_o <= instAddr_i;
					dataAddr_o <= dataAddr_i;
					loadInst_o <= inst_io;
					loadData_o <= 20'b0;
					pauseRequest <= 1'b0;
					
					case(ramOp_i)
						`MEM_SW: begin
							ext_be_n_o <= 4'b0000;
						end

						`MEM_SH: begin
							if(bytes_i == 2'b00) begin
								ext_be_n_o <= 4'b1100;
							end else if(bytes_i == 2'b10) begin
								ext_be_n_o <= 4'b0011;
							end else begin
								ext_be_n_o <= 4'b1111;
							end
						end

						`MEM_SB: begin
							if(bytes_i == 2'b00) begin
								ext_be_n_o <= 4'b1110;
							end else if(bytes_i == 2'b01) begin
								ext_be_n_o <= 4'b1101;
							end else if(bytes_i == 2'b10) begin
								ext_be_n_o <= 4'b1011;
							end else begin
								ext_be_n_o <= 4'b0111;
							end
						end
						
						default: begin
							ext_be_n_o <= 4'b1111;
						end
					endcase
					
				    if(base_read == 1'b1) begin
						nstate <= READ_BASE;
					end else if(base_write == 1'b1) begin
						nstate <= WRITE_BASE;
					end else if(ext_read == 1'b1) begin
						nstate <= READ_EXT;
					end else if(ext_write == 1'b1) begin
						nstate <= WRITE_EXT;
					end else begin
						nstate <= IDLE;
					end
				end
				
				READ_BASE: begin
					base_we_n_o <= 1'b1;
					base_ce_n_o <= 1'b0;
					base_oe_n_o <= 1'b0;
					base_be_n_o <= 4'b0000;
					ext_we_n_o <= 1'b1;
					ext_ce_n_o <= 1'b1;
					ext_oe_n_o <= 1'b1;
					ext_be_n_o <= 4'b1111;
					instAddr_o <= dataAddr_i;
					dataAddr_o <= 20'b0;
					loadInst_o <= 32'b0;
					loadData_o <= inst_io;
					pauseRequest <= 1'b1;      
						  
					case(ramOp_i) 
						`MEM_LB: begin
							if(bytes_i == 2'b00) begin
								loadData_o <= {{24{inst_io[7]}}, inst_io[7:0]};
							end else if(bytes_i == 2'b01) begin
								loadData_o <= {{24{inst_io[15]}}, inst_io[15:8]};
							end else if(bytes_i == 2'b10) begin
								loadData_o <= {{24{inst_io[23]}}, inst_io[23:16]};
							end else begin
								loadData_o <= {{24{inst_io[31]}}, inst_io[31:24]};
							end
						end
						
						`MEM_LBU: begin
							if(bytes_i == 2'b00) begin
								loadData_o <= {24'b0, inst_io[7:0]};
							end else if(bytes_i == 2'b01) begin
								loadData_o <= {24'b0, inst_io[15:8]};
							end else if(bytes_i == 2'b10) begin
								loadData_o <= {24'b0, inst_io[23:16]};
							end else begin
								loadData_o <= {24'b0, inst_io[31:24]};
							end
						end
												
						`MEM_LH: begin
							if(bytes_i == 2'b00) begin
								loadData_o <= {{16{inst_io[15]}}, inst_io[15:0]};
							end else begin
								loadData_o <= {{16{inst_io[31]}}, inst_io[31:16]};
							end
						end
						
						`MEM_LHU: begin
							if(bytes_i == 2'b00) begin
								loadData_o <= {16'b0, inst_io[15:0]};
							end else begin
								loadData_o <= {16'b0, inst_io[31:16]};
							end
						end
						
						default: begin
							loadData_o <= inst_io;
						end
					endcase
					
					/*if(base_read == 1'b1) begin
						nstate <= READ_BASE;
					end else if(base_write == 1'b1) begin
						nstate <= WRITE_BASE;
					end else if(ext_read == 1'b1) begin
						nstate <= READ_EXT;
					end else if(ext_write == 1'b1) begin
						nstate <= WRITE_EXT;
					end else begin
						nstate <= IDLE;
					end*/
					nstate <= IDLE;
				end
				
				WRITE_BASE: begin
					base_we_n_o <= 1'b0;
					base_ce_n_o <= 1'b0;
					base_oe_n_o <= 1'b1;
					base_be_n_o <= 4'b0000;
					ext_we_n_o <= 1'b1;
					ext_ce_n_o <= 1'b1;
					ext_oe_n_o <= 1'b1;
					ext_be_n_o <= 4'b1111;
					instAddr_o <= dataAddr_i;
					dataAddr_o <= 20'b0;
					loadInst_o <= 32'b0;
					loadData_o <= 20'b0;
					pauseRequest <= 1'b1;
					
					case(ramOp_i)
						`MEM_SW: begin
							base_be_n_o <= 4'b0000;
						end

						`MEM_SH: begin
							if(bytes_i == 2'b00) begin
								base_be_n_o <= 4'b1100;
							end else if(bytes_i == 2'b10) begin
								base_be_n_o <= 4'b0011;
							end else begin
								base_be_n_o <= 4'b1111;
							end
						end

						`MEM_SB: begin
							if(bytes_i == 2'b00) begin
								base_be_n_o <= 4'b1110;
							end else if(bytes_i == 2'b01) begin
								base_be_n_o <= 4'b1101;
							end else if(bytes_i == 2'b10) begin
								base_be_n_o <= 4'b1011;
							end else begin
								base_be_n_o <= 4'b0111;
							end
						end
						
						default: begin
							base_be_n_o <= 4'b1111;
						end
					endcase
					
					/*if(base_write == 1'b1) begin
						nstate <= WRITE_BASE;
					end else begin*/
						nstate <= WRITE_BASE_HOLD;
					//end
				end
				
				WRITE_BASE_HOLD: begin
					base_we_n_o <= 1'b1;
					base_ce_n_o <= 1'b0;
					base_oe_n_o <= 1'b1;
					base_be_n_o <= 4'b0000;
					ext_we_n_o <= 1'b1;
					ext_ce_n_o <= 1'b1;
					ext_oe_n_o <= 1'b1;
					ext_be_n_o <= 4'b1111;
					instAddr_o <= dataAddr_i;
					dataAddr_o <= 20'b0;
					loadInst_o <= 32'b0;
					loadData_o <= 20'b0;
					pauseRequest <= 1'b1;
					
					case(ramOp_i)
						`MEM_SW: begin
							base_be_n_o <= 4'b0000;
						end

						`MEM_SH: begin
							if(bytes_i == 2'b00) begin
								base_be_n_o <= 4'b1100;
							end else if(bytes_i == 2'b10) begin
								base_be_n_o <= 4'b0011;
							end else begin
								base_be_n_o <= 4'b1111;
							end
						end

						`MEM_SB: begin
							if(bytes_i == 2'b00) begin
								base_be_n_o <= 4'b1110;
							end else if(bytes_i == 2'b01) begin
								base_be_n_o <= 4'b1101;
							end else if(bytes_i == 2'b10) begin
								base_be_n_o <= 4'b1011;
							end else begin
								base_be_n_o <= 4'b0111;
							end
						end
						
						default: begin
							base_be_n_o <= 4'b1111;
						end
					endcase
					
					/*if(base_read == 1'b1) begin
						nstate <= READ_BASE;
					end else if(base_write == 1'b1) begin
						nstate <= WRITE_BASE;
					end else if(ext_read == 1'b1) begin
						nstate <= READ_EXT;
					end else if(ext_write == 1'b1) begin
						nstate <= WRITE_EXT;
					end else begin
						nstate <= IDLE;
					end*/
					nstate <= IDLE;
					
				end
				
				default: begin
				    base_we_n_o <= 1'b1;
					base_ce_n_o <= 1'b0;
					base_oe_n_o <= 1'b0;
					base_be_n_o <= 4'b0000;
					ext_we_n_o <= 1'b1;
					ext_ce_n_o <= 1'b1;
					ext_oe_n_o <= 1'b1;
					ext_be_n_o <= 4'b1111;
					instAddr_o <= instAddr_i;
					dataAddr_o <= 20'b0;
					loadInst_o <= inst_io;
					loadData_o <= 32'b0;
					pauseRequest <= 1'b0;
                    nstate <= IDLE;
				end
			
			endcase
		end			
    end
	 
endmodule	
