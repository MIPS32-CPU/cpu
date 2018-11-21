module rom(
    input wire rst,
    input wire clk,
    input wire [31:0] pc_i,
    
    output reg [31:0] inst_o
);

    reg [31:0] rom[0:4];
    initial $readmemh("D:/jiyuan/MIPS32/MIPS32.srcs/sources_1/new/rom.data", rom);
    
    always @ (*) begin
        if(rst == 1'b1) begin
            inst_o <= 32'b0;
        end else begin
            inst_o <= rom[pc_i[31:2]];
        end
    end
endmodule

