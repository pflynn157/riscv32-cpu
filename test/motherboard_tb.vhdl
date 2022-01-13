library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.std_logic_textio.all;

entity motherboard_tb is
end motherboard_tb;

architecture Behavior of motherboard_tb is

	-- The motherboard component
	component Motherboard is
		port (
            clk          : in std_logic;
            Dsp_Data     : out std_logic_vector(31 downto 0);
            Sata0_Cmd    : out std_logic_vector(4 downto 0);
            O_Sata0_Data : out std_logic_vector(31 downto 0);
            I_Sata0_Data : in std_logic_vector(31 downto 0)
		);
	end component;
    
    -- The display data
    signal Dsp_Data : std_logic_vector(31 downto 0) := X"00000000";
    
    -- Sata0 signals
    signal Sata0_Cmd : std_logic_vector(4 downto 0) := "00000";
    signal O_Sata0_Data, I_Sata0_Data : std_logic_vector(31 downto 0) := X"00000000";
	
	-- The clock signals
	signal clk : std_logic := '0';
	constant clk_period : time := 5 ns;
    
    -- File read procedure
    --function ReadSata(path : string; pos : integer) return std_logic_vector is
    --    variable data : std_logic_vector(31 downto 0) := X"00000001";
    --    file input : text open read_mode is path;
    --    variable read_line : line;
    --    variable current_pos : integer := 0;
    --begin
    --    while (not endfile(input)) and (current_pos < pos) loop
    --        readline(input, read_line);
    --        read(read_line, data);
    --    end loop;
    --    
    --    file_close(input);
    --    return data;
    --end ReadSata;
begin
	uut : Motherboard port map (
		clk => clk,
        Dsp_Data => Dsp_Data,
        Sata0_Cmd => Sata0_Cmd,
        O_Sata0_Data => O_Sata0_Data,
        I_Sata0_Data => I_Sata0_Data
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
    
    -- The SATA 0 harddrive
    process(Sata0_Cmd, O_Sata0_Data)
        variable pos : integer := 0;
        
        -- File stuff
        file input : text;
        variable read_line : line;
        variable current_pos : integer := 0;
        variable data : std_logic_vector(31 downto 0) := X"00000000";
    begin
        -- Seek
        if Sata0_Cmd = "00001" then
            pos := to_integer(unsigned(O_Sata0_Data));
        
        -- Read
        elsif Sata0_Cmd = "00010" then
            file_open(input, "../sata0.txt", read_mode);
            current_pos := 0;
            
            while (not endfile(input)) and (current_pos <= pos) loop
                readline(input, read_line);
                read(read_line, data);
                current_pos := current_pos + 1;
            end loop;
            
            file_close(input);
            I_Sata0_Data <= data;
        end if;
    end process;
end Behavior;
