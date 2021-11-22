library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity cpu_tb is
end cpu_tb;

architecture Behavior of cpu_tb is

    -- Declare the CPU component
    component CPU is
        port (
            clk     : in std_logic;
            I_instr : in std_logic_vector(31 downto 0);
            ready   : out std_logic;
            O_PC    : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- The clock signals
    signal clk : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    -- The other signals
    signal I_instr, O_PC : std_logic_vector(31 downto 0) := X"00000000";
    signal ready : std_logic := '0';
    
    -- Our test program
    constant SIZE : integer := 2;
    type instr_memory is array (0 to 1) of std_logic_vector(31 downto 0);
    signal memory : instr_memory := (
        "000000000110" & "00000" & "000" & "00010" & "0010011",   -- ADDI X2, X0, 6
        "000000000101" & "00000" & "000" & "00001" & "0010011"    -- ADDI X1, X0, 5
    );
begin
    uut : CPU port map (
        clk => clk,
        I_instr => I_instr,
        ready => ready,
        O_PC => O_PC
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
        I_instr <= memory(0);
        wait until ready = '1';
        
        for i in 1 to SIZE loop
            if to_integer(unsigned(O_PC)) < SIZE then
                I_instr <= memory(to_integer(unsigned(O_PC)));
                wait until ready = '1';
            end if;
        end loop;
        
        wait;
    end process;
end Behavior;