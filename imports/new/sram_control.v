`include<defines.v>

module sram_control (
	input wire clk,
	input wire rst,
	input wire [19:0] ramAddr_i,
	input wire [31:0] storeData_i,
	input wire [3:0] ramOp_i,
	input wire [1:0] bytes_i,
	
	output reg [31:0] loadData_o,
	output reg WE_n_o,
	output reg OE_n_o,
	output reg CE_n_o,
	output reg [3:0] be_n_o,
	output reg [19:0] ramAddr_o,
	output reg success_o,
	
	inout wire [31:0] data_io
);	
	
	reg [2:0] state, nstate;
	//wire write;
	assign data_io = (ramOp_i == `MEM_SW) ? storeData_i : ((ramOp_i == `MEM_SH) ? {2{storeData_i[15:0]}} : ((ramOp_i == `MEM_SB) ? {4{storeData_i[7:0]}} : 32'bz));
	//assign write = (ramOp_i == `MEM_SW || ramOp_i == `MEM_SH || ramOp_i == `MEM_SB) ? 1'b1 : 1'b0;
	
	parameter IDLE = 3'b00,
			  WRITE = 3'b10,
			  READ = 3'b11,
			  WRITEEND = 3'b100,
			  WRITE2 = 3'b101,
			  WRITE3 = 3'b110;
			  
	always @(posedge clk or posedge rst) begin
		if(rst == 1'b1) begin
			state <= IDLE;
		end else begin
			state <= nstate;
		end
	end
		
    always @(*) begin
    	if(rst == 1'b1 || ramOp_i == 4'b0) begin
			WE_n_o <= 1'b1;
			CE_n_o <= 1'b1;
			OE_n_o <= 1'b1;
			be_n_o <= 4'b1111;
			ramAddr_o <= 20'b0;
			loadData_o <= 32'b0;
			success_o <= 1'b0;
			nstate <= IDLE;
		end else begin
			ramAddr_o <= ramAddr_i;
			OE_n_o <= 1'b0;
            CE_n_o <= 1'b0;
			case(state) 
				IDLE: begin
					WE_n_o <= 1'b1;
					be_n_o <= 4'b0000;
					loadData_o <= 32'b0;
					success_o <= 1'b0;
					
					case(ramOp_i) 
						`MEM_LW: begin
							nstate <= READ;
						end
						`MEM_SW: begin
							nstate <= WRITE;
						end
						
						`MEM_SB: begin
							nstate <= WRITE;
						end
						
						`MEM_SH: begin
							nstate <= WRITE;
						end
						
						`MEM_LB: begin
							nstate <= READ;
						end
						
						`MEM_LH: begin
							nstate <= READ;
						end
						
						`MEM_LBU: begin
							nstate <= READ;
						end
						
						`MEM_LHU: begin
							nstate <= READ;
						end

						default: begin
							nstate <= IDLE;
						end
					endcase
				end
				
				
				READ: begin
                                
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
                    WE_n_o <= 1'b1;
                    be_n_o <= 4'b0000;
                    success_o <= 1'b1;
                    nstate <= IDLE;
                end
				
				
				WRITE: begin
				    WE_n_o <= 1'b0;
				    case(ramOp_i)
                        `MEM_SW: begin
                            be_n_o <= 4'b0000;
                        end

                        `MEM_SH: begin
                        	if(bytes_i == 2'b00) begin
                            	be_n_o <= 4'b1100;
                            end else if(bytes_i == 2'b10) begin
                            	be_n_o <= 4'b0011;
                            end else begin
                            	be_n_o <= 4'b1111;
                            end
                        end

                        `MEM_SB: begin
                        	if(bytes_i == 2'b00) begin
                            	be_n_o <= 4'b1110;
                            end else if(bytes_i == 2'b01) begin
                            	be_n_o <= 4'b1101;
                            end else if(bytes_i == 2'b10) begin
                            	be_n_o <= 4'b1011;
                            end else begin
                            	be_n_o <= 4'b0111;
                            end
                        end
                        
                        default: begin
                            be_n_o <= 4'b1111;
                        end
                    endcase
                    loadData_o <= 32'b0;
                    success_o <= 1'b0;
				    nstate <= WRITE2;
				end
				
				WRITE2: begin
				    WE_n_o <= 1'b1;
				    be_n_o <= 4'b1111;
				    loadData_o <= 32'b0;
                    success_o <= 1'b1;
				    nstate <= IDLE;
				end
				
				WRITEEND: begin
					success_o <= 1'b1;
					WE_n_o <= 1'b1;
                    be_n_o <= 4'b1111;
                    loadData_o <= 32'b0;
					
					nstate <= IDLE;
				end
				
				default: begin
				    
				    WE_n_o <= 1'b1;
                    be_n_o <= 4'b1111;
                    loadData_o <= 32'b0;
                    success_o <= 1'b0;
                    nstate <= IDLE;
				end
			
			endcase
		end			
    end
	 
endmodule	
