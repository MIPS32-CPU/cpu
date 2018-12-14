/******************************************
Regulations for the names of the wires:
ONLY define the OUTPUT wires of the parts.
In fact, one wire can link two ends.
*******************************************/

module CPU(
    input wire clk,
    input wire rst,
    input wire rxd,
    
    output wire [19:0] instAddr_o,
	output wire [19:0] dataAddr_o,
	
	output wire inst_WE_n_o,
	output wire inst_OE_n_o,
	output wire inst_CE_n_o,
	output wire [3:0] inst_be_n_o,
	
	output wire data_WE_n_o,
	output wire data_OE_n_o,
	output wire data_CE_n_o,
	output wire [3:0] data_be_n_o,
	
	output wire [15:0] led_o,
	output wire [3:0] dpy0_o,
	output wire [3:0] dpy1_o,
	
	output wire txd,
	
	// VGA
	output wire[2:0] video_red,
    output wire[2:0] video_green,
    output wire[1:0] video_blue,
    output wire video_hsync,
    output wire video_vsync,
    output wire video_clk,
    output wire video_de,
	
	inout wire [31:0] inst_io,
	inout wire [31:0] data_io
);
	
    //link the pc and IF/ID
    wire [31:0] pc_pc_o;
    wire pc_pause_o;
    wire [31:0] pc_exceptionType_o;
    
    //link IF/ID and ID
    wire [31:0] IF_ID_pc_o;
    wire [31:0] IF_ID_inst_o;
    wire [31:0] IF_ID_exceptionType_o;
    
    //link ID and registers , ID/EX
    wire [31:0] reg_readData1_o, reg_readData2_o;
    wire [31:0] HILO_HI_data_o, HILO_LO_data_o;
    wire [4:0] ID_readAddr1_o, ID_readAddr2_o;
    wire ID_readEnable1_o, ID_readEnable2_o;
    wire ID_writeEnable_o;
    wire [4:0] ID_writeAddr_o;
    wire [31:0] ID_oprand1_o, ID_oprand2_o;
    wire [4:0] ID_ALUop_o;
    wire ID_branchEnable_o;
    wire [31:0] ID_branchAddr_o;
    wire [1:0] ID_writeHILO_o;
    wire ID_signed_o;
    wire [31:0] ID_inst_o, ID_pc_o;
    wire ID_pause_o;
    wire ID_write_CP0_o;
    wire [4:0] ID_write_CP0_addr_o;
    wire [4:0] ID_read_CP0_addr_o;
    wire [31:0] ID_exceptionType_o;
    wire ID_in_delay_slot_o, ID_next_in_delay_slot_o;
    
    //link ID/EX and EX
    wire [4:0] ID_EX_ALUop_o;
    wire [31:0] ID_EX_oprand1_o, ID_EX_oprand2_o;
    wire [4:0] ID_EX_writeAddr_o;
    wire ID_EX_writeEnable_o;
    wire [1:0] ID_EX_writeHILO_o;
    wire ID_EX_signed_o;
    wire [31:0] ID_EX_inst_o, ID_EX_pc_o;
    wire ID_EX_write_CP0_o;
    wire [4:0] ID_EX_write_CP0_addr_o;
    wire [31:0] ID_EX_exceptionType_o;
    wire ID_EX_in_delay_slot_o, ID_EX_next_in_delay_slot_o;
    
    //link EX and EX/MEM
    wire [31:0] EX_HI_data_o, EX_LO_data_o;
    wire [4:0] EX_writeAddr_o;
    wire EX_writeEnable_o;
    wire [1:0] EX_writeHILO_o;
    wire [31:0] EX_dividend_o, EX_divider_o;
    wire EX_pause_o, EX_signed_o, EX_start_o;
    wire [31:0] EX_storeData_o;
    wire [3:0] EX_ramOp_o;
    wire EX_write_CP0_o;
    wire [4:0] EX_write_CP0_addr_o;
    wire [31:0] EX_exceptionType_o;
    wire EX_in_delay_slot_o;
    wire [31:0] EX_pc_o;
       
    //link EX/MEM and MEM
    wire [31:0] EX_MEM_HI_data_o, EX_MEM_LO_data_o;
    wire [4:0] EX_MEM_writeAddr_o;
    wire EX_MEM_writeEnable_o;
    wire [1:0] EX_MEM_writeHILO_o;
    wire [31:0] EX_MEM_storeData_o;
    wire [3:0] EX_MEM_ramOp_o;
    wire EX_MEM_write_CP0_o;
    wire [4:0] EX_MEM_write_CP0_addr_o;
    wire [31:0] EX_MEM_exceptionType_o;
    wire EX_MEM_in_delay_slot_o;
    wire [31:0] EX_MEM_pc_o;
     
    //link MEM and MEM/WB
    wire [31:0] MEM_HI_data_o, MEM_LO_data_o;
    wire [4:0] MEM_writeAddr_o;
    wire MEM_writeEnable_o;
    wire [1:0] MEM_writeHILO_o;
    wire [3:0] MEM_ramOp_o;
    wire [31:0] MEM_ramAddr_o;
    wire [31:0] MEM_storeData_o;
    wire MEM_pause_o;
    wire MEM_write_CP0_o;
    wire [4:0] MEM_write_CP0_addr_o;
    wire [31:0] MEM_exceptionType_o;
    wire MEM_in_delay_slot_o;
    wire [31:0] MEM_pc_o;
    wire [31:0] MEM_CP0_epc_o, MEM_CP0_ebase_o, MEM_CP0_index_o, MEM_CP0_random_o, MEM_CP0_entrylo0_o, MEM_CP0_entrylo1_o, MEM_CP0_entryhi_o;
    wire MEM_tlbwi_o, MEM_tlbwr_o;
     
    //link MEM/WB and registers
    wire [31:0] MEM_WB_HI_data_o, MEM_WB_LO_data_o;
    wire [4:0] MEM_WB_writeAddr_o;
    wire MEM_WB_writeEnable_o; 
    wire [1:0] MEM_WB_writeHILO_o;
    wire MEM_WB_write_CP0_o;
    wire [4:0] MEM_WB_write_CP0_addr_o;
    
    //control
    wire [5:0] ctr_stall_o;
    wire ctr_flush_o;
    wire [31:0] ctr_exceptionHandleAddr_o;

    //CP0 register
    wire [31:0] CP0_readData_o, CP0_status_o, CP0_epc_o, CP0_cause_o, CP0_ebase_o, CP0_index_o, CP0_random_o, CP0_entrylo0_o, 
    CP0_entrylo1_o, CP0_entryhi_o, CP0_badVaddr_o;

    //div module
    wire [63:0] DIV_result_o;
    wire DIV_success_o;
    
    //sram control
    wire [31:0] base_load_data_o; 
    wire [19:0] base_ramAddr_o;
    wire base_CE_n_o, base_WE_n_o, base_OE_n_o;
    wire [3:0] base_be_n_o;
	wire [31:0] ext_load_data_o; 
	wire [19:0] ext_ramAddr_o;
	wire ext_CE_n_o, ext_WE_n_o, ext_OE_n_o;
	wire [3:0] ext_be_n_o;
	wire sram_pause_o;
	wire [31:0] sram_data_o;
    
    //MMU
    wire [31:0] MMU_load_data_o, MMU_load_inst_o, MMU_storeData_o;
    wire [3:0] MMU_ramOp_o;
    wire [19:0] MMU_instAddr_o, MMU_dataAddr_o;
    wire [1:0] MMU_bytes_o;
    wire MMU_tlbmiss_o, MMU_load_o, MMU_EX_tlbmiss_o;
    wire [3:0] MMU_uartOp_o;
    wire [31:0] MMU_uart_storeData_o;
    
    //uart control
	wire [31:0] uart_loadData_o;
	wire uart_pause_o;
	wire [31:0] uart_data_o;
	wire uart_txd, uart_dataReady, uart_writeReady;
	assign txd = uart_txd;
	/*assign led_o[15] = uart_dataReady;
    assign led_o[14] = rxd;
    assign led_o[13] = txd;
    assign led_o[12] = uart_writeReady;*/
    assign led_o[15:8] = uart_loadData_o[7:0];
    wire mem_pause_o;
    assign mem_pause_o = uart_pause_o || sram_pause_o;	
    
    assign inst_CE_n_o = base_CE_n_o,  inst_WE_n_o = base_WE_n_o, 
    	   inst_OE_n_o = base_OE_n_o;
    assign inst_be_n_o = base_be_n_o;
    assign instAddr_o = base_ramAddr_o;
    
	assign data_CE_n_o = ext_CE_n_o,  data_WE_n_o = ext_WE_n_o, 
		   data_OE_n_o = ext_OE_n_o;
	assign data_be_n_o = ext_be_n_o;
	assign dataAddr_o = ext_ramAddr_o;
    
    pc pc0(
	        .clk(clk),                              
	        .rst(rst), 
	        .branchEnable_i(ID_branchEnable_o),    	
	        .branchAddr_i(ID_branchAddr_o),
	        .stall(ctr_stall_o), 
	        .flush(ctr_flush_o),
	        .exceptionHandleAddr_i(ctr_exceptionHandleAddr_o),
	        
	        .pc_o(pc_pc_o),
	        .pauseRequest(pc_pause_o),
	        .exceptionType_o(pc_exceptionType_o)							
	        
	    );
	    
	    
	    
	    IF_ID IF_ID0(
	        .clk(clk),                              
	        .rst(rst), 
	        .pc_i(pc_pc_o),                         
	        .inst_i(MMU_load_inst_o), 
	        .stall(ctr_stall_o),
	        .flush(ctr_flush_o),
	        .exceptionType_i(pc_exceptionType_o),
	        
	        .pc_o(IF_ID_pc_o),                      
	        .inst_o(IF_ID_inst_o),
	        .exceptionType_o(IF_ID_exceptionType_o)
	    );
	    
	    
	    
	    ID ID0(
	        .clk(clk),                              
	        .rst(rst), 
	        .inst_i(IF_ID_inst_o),                  
	        .pc_i(IF_ID_pc_o), 
	        .readData1_i(reg_readData1_o),          
	        .readData2_i(reg_readData2_o),
	        .HI_data_i(HILO_HI_data_o),				
	        .LO_data_i(HILO_LO_data_o),
	        .EX_writeEnable_i(EX_writeEnable_o),	
	        .EX_writeAddr_i(EX_writeAddr_o),
	        .EX_writeHI_data_i(EX_HI_data_o),		
	        .EX_writeLO_data_i(EX_LO_data_o),
	        .EX_writeHILO_i(EX_writeHILO_o),		
	        .MEM_writeEnable_i(MEM_writeEnable_o),
	        .MEM_writeAddr_i(MEM_writeAddr_o), 		
	        .MEM_writeHI_data_i(MEM_HI_data_o),
	        .MEM_writeLO_data_i(MEM_LO_data_o),		
	        .MEM_writeHILO_i(MEM_writeHILO_o),
	        .readAddr1_o(ID_readAddr1_o),           
	        .readAddr2_o(ID_readAddr2_o), 
	        .readEnable1_o(ID_readEnable1_o),       
	        .readEnable2_o(ID_readEnable2_o), 
	        .writeEnable_o(ID_writeEnable_o),       
	        .writeAddr_o(ID_writeAddr_o),
	        .oprand1_o(ID_oprand1_o),               
	        .oprand2_o(ID_oprand2_o), 
	        .branchEnable_o(ID_branchEnable_o),     
	        .branchAddr_o(ID_branchAddr_o), 
	        .ALUop_o(ID_ALUop_o),					
	        .writeHILO_o(ID_writeHILO_o),
	        .signed_o(ID_signed_o),					
	        .inst_o(ID_inst_o),
	        .pc_o(ID_pc_o),							
	        .pauseRequest(ID_pause_o),
	        .EX_ramOp_i(EX_ramOp_o),
	        .next_in_delay_slot_i(ID_EX_next_in_delay_slot_o),
	        .next_in_delay_slot_o(ID_next_in_delay_slot_o),
	        .in_delay_slot_o(ID_in_delay_slot_o),
	        .exceptionType_o(ID_exceptionType_o),
	        .write_CP0_o(ID_write_CP0_o),
	        .write_CP0_addr_o(ID_write_CP0_addr_o),
	        .read_CP0_addr_o(ID_read_CP0_addr_o),
	        .CP0_data_i(CP0_readData_o),
	        .cause_i(CP0_cause_o),
	        .EX_write_CP0_i(EX_write_CP0_o),
	        .EX_write_CP0_addr_i(EX_write_CP0_addr_o),
	        .MEM_write_CP0_i(MEM_write_CP0_o),
	        .MEM_write_CP0_addr_i(MEM_write_CP0_addr_o),
	        .exceptionType_i(IF_ID_exceptionType_o)
	    );
	    
	    
	    registers regs0(
	        .clk(clk),                              
	        .rst(rst), 
	        .readEnable1_i(ID_readEnable1_o),       
	        .readEnable2_i(ID_readEnable2_o), 
	        .readAddr1_i(ID_readAddr1_o),           
	        .readAddr2_i(ID_readAddr2_o),
	        .writeEnable_i(MEM_WB_writeEnable_o),   
	        .writeAddr_i(MEM_WB_writeAddr_o), 
	        .writeData_i(MEM_WB_LO_data_o),
	        .led_o(led_o[7:0]),
	        .dpy0_o(dpy0_o),
	        .dpy1_o(dpy1_o),
	        .readData1_o(reg_readData1_o), 
	        .readData2_o(reg_readData2_o)
	    );
	    
	    
	    
	    ID_EX ID_EX0(
	        .clk(clk),                              
	        .rst(rst), 
	        .ALUop_i(ID_ALUop_o),                   
	        .oprand1_i(ID_oprand1_o), 
	        .oprand2_i(ID_oprand2_o),               
	        .writeAddr_i(ID_writeAddr_o),
	        .writeEnable_i(ID_writeEnable_o),       
	        .ALUop_o(ID_EX_ALUop_o), 
	        .oprand1_o(ID_EX_oprand1_o),            
	        .oprand2_o(ID_EX_oprand2_o), 
	        .writeAddr_o(ID_EX_writeAddr_o),        
	        .writeEnable_o(ID_EX_writeEnable_o),
	        .writeHILO_i(ID_writeHILO_o),			
	        .writeHILO_o(ID_EX_writeHILO_o),
	        .stall(ctr_stall_o),					
	        .signed_o(ID_EX_signed_o),
	        .signed_i(ID_signed_o),					
	        .inst_i(ID_inst_o),
	        .pc_i(ID_pc_o),							
	        .inst_o(ID_EX_inst_o),
	        .pc_o(ID_EX_pc_o),
	        .next_in_delay_slot_i(ID_next_in_delay_slot_o),
	        .next_in_delay_slot_o(ID_EX_next_in_delay_slot_o),
	        .in_delay_slot_i(ID_in_delay_slot_o),
	        .in_delay_slot_o(ID_EX_in_delay_slot_o),
	        .exceptionType_i(ID_exceptionType_o),
	        .exceptionType_o(ID_EX_exceptionType_o),
	        .write_CP0_i(ID_write_CP0_o),
	        .write_CP0_addr_i(ID_write_CP0_addr_o),
	        .write_CP0_o(ID_EX_write_CP0_o),
	        .write_CP0_addr_o(ID_EX_write_CP0_addr_o),
	        .flush(ctr_flush_o)
	    );
	    
	   
	    
	    EX EX0(
	    	.clk(clk), 								
	    	.rst(rst), 
	    	.ALUop_i(ID_EX_ALUop_o),				
	    	.writeHILO_i(ID_EX_writeHILO_o),
	    	.oprand1_i(ID_EX_oprand1_o),			
	    	.oprand2_i(ID_EX_oprand2_o), 			
	    	.writeAddr_i(ID_EX_writeAddr_o),		
	    	.writeEnable_i(ID_EX_writeEnable_o), 	
	    	.HI_data_o(EX_HI_data_o),				
	    	.LO_data_o(EX_LO_data_o),				
	    	.writeHILO_o(EX_writeHILO_o),			
	    	.writeAddr_o(EX_writeAddr_o),			
	    	.writeEnable_o(EX_writeEnable_o),		
	    	.signed_o(EX_signed_o),
	    	.start_o(EX_start_o),					
	    	.divider_o(EX_divider_o),
	    	.dividend_o(EX_dividend_o),				
	    	.result_div_i(DIV_result_o),
	    	.success_i(DIV_success_o),				
	    	.pauseRequest(EX_pause_o),
	    	.signed_i(ID_EX_signed_o),				
	    	.inst_i(ID_EX_inst_o),
	    	.pc_i(ID_EX_pc_o),
	    	.pc_o(EX_pc_o),						
	    	.ramOp_o(EX_ramOp_o),
	    	.storeData_o(EX_storeData_o),
	    	.in_delay_slot_i(ID_EX_in_delay_slot_o),
	    	.in_delay_slot_o(EX_in_delay_slot_o),
	    	.exceptionType_i(ID_EX_exceptionType_o),
	    	.exceptionType_o(EX_exceptionType_o),
	    	.write_CP0_i(ID_EX_write_CP0_o),
			.write_CP0_addr_i(ID_EX_write_CP0_addr_o),
			.write_CP0_o(EX_write_CP0_o),
			.write_CP0_addr_o(EX_write_CP0_addr_o)
	    );
	    
	    
	    
	    EX_MEM EX_MEM0(
	    	.clk(clk), 								
	    	.rst(rst), 
	    	.HI_data_i(EX_HI_data_o),				
	    	.LO_data_i(EX_LO_data_o),
	    	.writeAddr_i(EX_writeAddr_o), 			
	    	.writeHILO_i(EX_writeHILO_o),
	    	.writeEnable_i(EX_writeEnable_o), 		
	    	.HI_data_o(EX_MEM_HI_data_o),
	    	.LO_data_o(EX_MEM_LO_data_o),			
	    	.writeHILO_o(EX_MEM_writeHILO_o),
	    	.writeAddr_o(EX_MEM_writeAddr_o), 		
	    	.writeEnable_o(EX_MEM_writeEnable_o),
	    	.stall(ctr_stall_o),					
	    	.storeData_i(EX_storeData_o),
	    	.ramOp_i(EX_ramOp_o),					
	    	.storeData_o(EX_MEM_storeData_o),
	    	.ramOp_o(EX_MEM_ramOp_o),
	    	.in_delay_slot_i(EX_in_delay_slot_o),
	    	.in_delay_slot_o(EX_MEM_in_delay_slot_o),
	    	.exceptionType_i(EX_exceptionType_o),
	    	.exceptionType_o(EX_MEM_exceptionType_o),
	    	.pc_i(EX_pc_o),
	    	.pc_o(EX_MEM_pc_o),
	    	.write_CP0_i(EX_write_CP0_o),
			.write_CP0_addr_i(EX_write_CP0_addr_o),
			.write_CP0_o(EX_MEM_write_CP0_o),
			.write_CP0_addr_o(EX_MEM_write_CP0_addr_o),
			.flush(ctr_flush_o)
	    );
	    
	  
	    
	    MEM MEM0(
	    	.clk(clk), 								
	    	.rst(rst), 
	        .HI_data_i(EX_MEM_HI_data_o),			
	        .LO_data_i(EX_MEM_LO_data_o),			
	        .writeAddr_i(EX_MEM_writeAddr_o), 		
	        .writeHILO_i(EX_MEM_writeHILO_o),
	        .LO_data_o(MEM_LO_data_o),				
	        .HI_data_o(MEM_HI_data_o),
	        .writeEnable_i(EX_MEM_writeEnable_o), 	
	        .writeHILO_o(MEM_writeHILO_o),
	        .writeAddr_o(MEM_writeAddr_o), 			
	        .writeEnable_o(MEM_writeEnable_o),
	        .storeData_i(EX_MEM_storeData_o),		
	        .ramOp_i(EX_MEM_ramOp_o),
	        .storeData_o(MEM_storeData_o),			
	        .ramOp_o(MEM_ramOp_o),
	        .ramAddr_o(MEM_ramAddr_o),				
	        .load_data_i(MMU_load_data_o),
	        .in_delay_slot_i(EX_MEM_in_delay_slot_o),
	       	.in_delay_slot_o(MEM_in_delay_slot_o),
	       	.exceptionType_i(EX_MEM_exceptionType_o),
	       	.exceptionType_o(MEM_exceptionType_o),
	       	.pc_i(EX_MEM_pc_o),
	       	.write_CP0_i(EX_MEM_write_CP0_o),
			.write_CP0_addr_i(EX_MEM_write_CP0_addr_o),
			.write_CP0_o(MEM_write_CP0_o),
			.write_CP0_addr_o(MEM_write_CP0_addr_o),
			.CP0_status_i(CP0_status_o),
			.CP0_cause_i(CP0_cause_o),
			.CP0_epc_i(CP0_epc_o),
			.CP0_ebase_i(CP0_ebase_o),
			.pc_o(MEM_pc_o),
			.CP0_epc_o(MEM_CP0_epc_o),
			.CP0_ebase_o(MEM_CP0_ebase_o),
			.WB_write_CP0_i(MEM_WB_write_CP0_o),
			.WB_write_CP0_addr_i(MEM_WB_write_CP0_addr_o),
			.WB_write_CP0_data_i(MEM_WB_LO_data_o),
			.CP0_index_i(CP0_index_o),
			.CP0_random_i(CP0_random_o),
			.CP0_entrylo0_i(CP0_entrylo0_o),
			.CP0_entrylo1_i(CP0_entrylo1_o),
			.CP0_entryhi_i(CP0_entryhi_o),
			.CP0_index_o(MEM_CP0_index_o),
			.CP0_random_o(MEM_CP0_random_o),
			.CP0_entrylo0_o(MEM_CP0_entrylo0_o),
			.CP0_entrylo1_o(MEM_CP0_entrylo1_o),
			.CP0_entryhi_o(MEM_CP0_entryhi_o),
			.tlbwi(MEM_tlbwi_o),
			.tlbwr(MEM_tlbwr_o)
	    );
	    
	
	    
	   	MEM_WB MEM_WB0(
			.clk(clk), 								
			.rst(rst), 
			.HI_data_i(MEM_HI_data_o),				
			.LO_data_i(MEM_LO_data_o),			
			.writeAddr_i(MEM_writeAddr_o), 			
			.writeHILO_i(MEM_writeHILO_o),
			.LO_data_o(MEM_WB_LO_data_o),			
			.HI_data_o(MEM_WB_HI_data_o),
			.writeEnable_i(MEM_writeEnable_o), 		
			.writeHILO_o(MEM_WB_writeHILO_o),
			.writeAddr_o(MEM_WB_writeAddr_o), 		
			.writeEnable_o(MEM_WB_writeEnable_o),
			.stall(ctr_stall_o),
			.write_CP0_i(MEM_write_CP0_o),
			.write_CP0_addr_i(MEM_write_CP0_addr_o),
			.write_CP0_o(MEM_WB_write_CP0_o),
			.write_CP0_addr_o(MEM_WB_write_CP0_addr_o),
			.flush(ctr_flush_o)
	    );
	    
	    
	    
	    HILO HILO0(
	    	.clk(clk),								
	    	.rst(rst),
	    	.writeEnable_i(MEM_WB_writeHILO_o),		
	    	.HI_data_i(MEM_WB_HI_data_o),
	    	.LO_data_i(MEM_WB_LO_data_o),			
	    	.HI_data_o(HILO_HI_data_o),
	    	.LO_data_o(HILO_LO_data_o)
	    );
	    
	    control control0(
	    	.rst(rst),								
	    	.stall_from_exe(EX_pause_o),
	    	.stall(ctr_stall_o),					
	    	.stall_from_id(ID_pause_o),
	    	.stall_from_mem(mem_pause_o),
	    	.exceptionType_i(MEM_exceptionType_o),
	    	.CP0_ebase_i(MEM_CP0_ebase_o),
	    	.CP0_epc_i(MEM_CP0_epc_o),
	    	.flush(ctr_flush_o),
	    	.exceptionHandleAddr_o(ctr_exceptionHandleAddr_o),
	    	.stall_from_pc(pc_pause_o),
	    	.tlbmiss_i(MMU_tlbmiss_o)
	    );
	    
	    CP0 CP0_0(
			.clk(clk),
			.rst(rst),
			.writeEnable_i(MEM_WB_write_CP0_o),
			.writeAddr_i(MEM_WB_write_CP0_addr_o),
			.writeData_i(MEM_WB_LO_data_o),
			.readAddr_i(ID_read_CP0_addr_o),
			.int_i(6'b0),
			.exceptionAddr_i(MEM_pc_o),
			.exceptionType_i(MEM_exceptionType_o),
			.in_delay_slot_i(MEM_in_delay_slot_o),
			.badVaddr_i(EX_MEM_LO_data_o),
	
			.readData_o(CP0_readData_o),
			.status_o(CP0_status_o),
			.epc_o(CP0_epc_o),
			.cause_o(CP0_cause_o),
			.ebase_o(CP0_ebase_o),
			.tlbmiss_i(MMU_tlbmiss_o),
			.load_i(MMU_load_o),
			.index_o(CP0_index_o),
			.random_o(CP0_random_o),
			.entrylo0_o(CP0_entrylo0_o),
			.entrylo1_o(CP0_entrylo1_o),
			.entryhi_o(CP0_entryhi_o),
			.badVaddr_o(CP0_badVaddr_o)
		);
	
	    div div0(
	    	.clk(clk),								
	    	.rst(rst),
	    	.signed_i(EX_signed_o),					
	    	.dividend_i(EX_dividend_o),
	    	.divider_i(EX_divider_o),				
	    	.start_i(EX_start_o),
	    	.concell_i(1'b0),						
	    	.result_o(DIV_result_o),
	    	.success_o(DIV_success_o)
	    );
	    
	    sram_control sram_control0(
	    	.clk(clk),							
	    	.rst(rst),
	    	.instAddr_i(MMU_instAddr_o),				
	    	.storeData_i(MMU_storeData_o),
	    	.ramOp_i(MMU_ramOp_o),					
	    	.loadData_o(ext_load_data_o),
	    	.bytes_i(MMU_bytes_o),
	    	.ext_ce_n_o(ext_CE_n_o),					
	    	.ext_we_n_o(ext_WE_n_o),						
	    	.ext_oe_n_o(ext_OE_n_o),					
	    	.ext_be_n_o(ext_be_n_o),
	    	.base_ce_n_o(base_CE_n_o),
	    	.base_we_n_o(base_WE_n_o),
	    	.base_oe_n_o(base_OE_n_o),
	    	.base_be_n_o(base_be_n_o),
	    	.inst_io(inst_io),
	    	.dataAddr_o(ext_ramAddr_o),
	    	.instAddr_o(base_ramAddr_o),
	    	.pauseRequest(sram_pause_o),
	    	.dataAddr_i(MMU_dataAddr_o),
	    	.loadInst_o(base_load_data_o),
	    	.EX_ramOp_i(EX_ramOp_o),
	    	.EX_ramAddr_i(EX_LO_data_o),
	    	.EX_tlbmiss_i(MMU_EX_tlbmiss_o),
	    	.data_io(data_io)
	    );
	    
	    MMU MMU0(
	    	.clk(clk),
	    	.rst(rst),
	    	.data_ramAddr_i(MEM_ramAddr_o),
	    	.inst_ramAddr_i(pc_pc_o),
	    	.ramOp_i(MEM_ramOp_o),
	    	.storeData_i(MEM_storeData_o),
	    	.load_data_i(ext_load_data_o),
	    	.load_inst_i(base_load_data_o),
	    	
	    	
	    	.ramOp_o(MMU_ramOp_o),
	    	.load_data_o(MMU_load_data_o),
	    	.load_inst_o(MMU_load_inst_o),
	    	.storeData_o(MMU_storeData_o),
	    	.instAddr_o(MMU_instAddr_o),
	    	.dataAddr_o(MMU_dataAddr_o),
	    	.bytes_o(MMU_bytes_o),
	    	.index_i(MEM_CP0_index_o),
	    	.random_i(MEM_CP0_random_o),
	    	.entrylo0_i(MEM_CP0_entrylo0_o),
	    	.entrylo1_i(MEM_CP0_entrylo1_o),
	    	.entryhi_i(MEM_CP0_entryhi_o),
	    	.tlbwi(MEM_tlbwi_o),
	    	.tlbwr(MEM_tlbwr_o),
	    	.tlbmiss(MMU_tlbmiss_o),
	    	.load_o(MMU_load_o),
	    	.EX_ramAddr_i(EX_LO_data_o),
	    	.EX_tlbmiss(MMU_EX_tlbmiss_o),
	    	.uart_load_data_i(uart_loadData_o),
	    	.uartOp_o(MMU_uartOp_o),
	    	.uart_storeData_o(MMU_uart_storeData_o),
	    	.dataReady(uart_dataReady),
	    	.writeReady(uart_writeReady)
	    );
	    
	  uart_control uart_control0(
	  		.clk(clk),
	  		.rst(rst),
	  		.rxd(rxd),
	  		.storeData(MMU_uart_storeData_o),
	  		.EX_uartOp_i(EX_ramOp_o),
	  		.EX_addr_i(EX_LO_data_o),
	  		.uartOp_i(MMU_uartOp_o),
	  		
	  		.txd(uart_txd),
	  		.loadData_o(uart_loadData_o),
	  		.dataReady(uart_dataReady),
	  		.pauseRequest(uart_pause_o),
	  		.writeReady(uart_writeReady)
	  );
	  
	  //图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
      wire [11:0] hdata;
      assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
      assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
      assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
      assign video_clk = clk;
      vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
          .clk(clk), 
          .hdata(hdata), //横坐标
          .vdata(),      //纵坐标
          .hsync(video_hsync),
          .vsync(video_vsync),
          .data_enable(video_de)
      );
	  
endmodule
    
    
    
