----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2018/12/31 00:42:40
-- Design Name: 
-- Module Name: flash0 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity flash0 is
    Port ( addr : in  STD_LOGIC_VECTOR (22 downto 0);
           data_out : out  STD_LOGIC_VECTOR (15 downto 0);
           success: out std_logic;
			  
			  clk : in std_logic;
			  reset : in std_logic;
			  
			  flash_byte : out std_logic;--BYTE#
			  flash_vpen : out std_logic;
			  flash_ce : out std_logic;
			  flash_oe : out std_logic;
			  flash_we : out std_logic;
			  flash_rp : out std_logic;
			  flash_addr : out std_logic_vector(22 downto 0);
			  flash_data : inout std_logic_vector(15 downto 0);
			  
           ctl_read : in  STD_LOGIC	
         );
end flash0;

architecture Behavioral of flash0 is
    type flash_state is (
		waiting,
		read1, read2, read3, read4,
		done
	);
	signal state : flash_state := waiting;
	signal next_state : flash_state := waiting;
begin

    flash_byte <= '1';
	flash_vpen <= '1';
	flash_ce <= '0';
	flash_rp <= '1';
	
	process (clk, reset, ctl_read)
	begin
		if (reset = '1') then
		      data_out <= flash_data;
		      success <= '0';
			flash_oe <= '1';
			flash_we <= '1';
			state <= waiting;
			next_state <= waiting;
			flash_data <= (others => 'Z');
		elsif (clk'event and clk = '1') then
			case state is
				when waiting =>
				    success <= '0';
--				    read_a_char <= '0';
				    if (ctl_read = '1') then
						flash_we <= '0';
						state <= read1;
				    end if;
				when read1 =>
					flash_data <= x"00FF";
					state <= read2;
				when read2 =>
					flash_we <= '1';
					state <= read3;
				when read3 =>
					flash_oe <= '0';
					flash_addr <= addr;
					flash_data <= (others => 'Z');
					state <= read4;
				when read4 =>
					state <= done;
				when others =>
				    success <= '1';
				    data_out <= flash_data;
					flash_oe <= '1';
					flash_we <= '1';
					flash_data <= (others => 'Z');
					state <= waiting;
			end case;
		end if;
	end process;


end Behavioral;
