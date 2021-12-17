library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity motherboard_tb is
end motherboard_tb;

architecture Behavior of motherboard_tb is

	-- The motherboard component
	component Motherboard is
		port (
			clk	: in std_logic
		);
	end component;
	
	-- The clock signals
	signal clk : std_logic := '0';
	constant clk_period : time := 5 ns;
begin
	uut : Motherboard port map (
		clk => clk
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
end Behavior;