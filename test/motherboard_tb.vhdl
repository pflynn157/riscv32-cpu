library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

entity motherboard_tb is
end motherboard_tb;

architecture Behavior of motherboard_tb is

	-- The motherboard component
	component Motherboard is
		port (
            clk	    : in std_logic;
            Dsp_Data : out std_logic_vector(31 downto 0)
		);
	end component;
    
    -- The display data
    signal Dsp_Data : std_logic_vector(31 downto 0) := X"00000000";
	
	-- The clock signals
	signal clk : std_logic := '0';
	constant clk_period : time := 5 ns;
begin
	uut : Motherboard port map (
		clk => clk,
        Dsp_Data => Dsp_Data
	);
	
	-- Create the clock
	I_clk_process : process
	begin
		clk <= '0';
		wait for clk_period / 2;
		clk <= '1';
		wait for clk_period / 2;
	end process;
	
	-- Run the CPU
	sim_proc : process
	begin
		wait;
	end process;
    
    -- The monitor
    process(Dsp_Data)
        variable l : line;
        variable i1, i2, i3, i4 : integer := 0;
    begin
        i1 := to_integer(unsigned(Dsp_Data(31 downto 24)));
        i2 := to_integer(unsigned(Dsp_Data(23 downto 16)));
        i3 := to_integer(unsigned(Dsp_Data(15 downto 8)));
        i4 := to_integer(unsigned(Dsp_Data(7 downto 0)));
    
        write(l, character'val(i1));
        write(l, character'val(i2));
        write(l, character'val(i3));
        write(l, character'val(i4));
        writeline(output, l);
    end process;
end Behavior;
