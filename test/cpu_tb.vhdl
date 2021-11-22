library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity cpu_tb is
end cpu_tb;

architecture Behavior of cpu_tb is

    -- Declare the CPU component
    component CPU is
        port (
            clk           : in std_logic;
            I_instr       : in std_logic_vector(31 downto 0);
            O_PC          : out std_logic_vector(31 downto 0);
            O_Mem_Write   : out std_logic;
            O_Mem_Address : out std_logic_vector(31 downto 0);
            O_Mem_Data    : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- Declare the memory component
    component Memory is
        port (
            clk      : in std_logic;
            I_write  : in std_logic;
            data_len : in std_logic_vector(1 downto 0);
            address  : in std_logic_vector(31 downto 0);
            I_data   : in std_logic_vector(31 downto 0);
            O_data   : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- The clock signals
    signal clk : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    -- The other signals
    signal I_instr, O_PC, O_Mem_Address, O_Mem_Data : std_logic_vector(31 downto 0) := X"00000000";
    signal O_Mem_Write : std_logic := '0';
    
    -- Memory signals
    signal I_write : std_logic := '0';
    signal data_len : std_logic_vector(1 downto 0) := "00";
    signal address, I_data, O_data : std_logic_vector(31 downto 0) := X"00000000";
    
    -- Our test program
    constant SIZE : integer := 8;
    type instr_memory is array (0 to (SIZE - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory : instr_memory := (
        "000000000101" & "00000" & "000" & "00001" & "0010011",   -- ADDI X1, X0, 5
        "000000000110" & "00000" & "000" & "00010" & "0010011",   -- ADDI X2, X0, 6
        "000000001010" & "00010" & "000" & "00011" & "0010011",   -- ADDI X3, X2, 10
        "000000000100" & "00000" & "000" & "00001" & "0010011",   -- ADDI X1, X0, 4
        "000000000110" & "00000" & "000" & "00010" & "0010011",   -- ADDI X2, X0, 6
        "000000000110" & "00000" & "000" & "00010" & "0010011",   -- ADDI X2, X0, 6
        "0000000" & "00000" & "00001" & "000" & "00000" & "0100011",   -- SB X1, [X0, 0]
        "000000000111" & "00000" & "000" & "00010" & "0010011"    -- ADDI X2, X0, 7
    );
begin
    uut : CPU port map (
        clk => clk,
        I_instr => I_instr,
        O_PC => O_PC,
        O_Mem_Write => O_Mem_Write,
        O_Mem_Address => O_Mem_Address,
        O_Mem_Data => O_Mem_Data
    );
    
    -- Connect memory
    mem_uut : Memory port map(
        clk => clk,
        I_write => I_write,
        data_len => data_len,
        address => address,
        I_data => I_data,
        O_data => O_data
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
        I_instr <= rom_memory(0);
        wait until O_PC'event;
        
        for i in 1 to SIZE loop
            if to_integer(unsigned(O_PC)) < SIZE then
                I_instr <= rom_memory(to_integer(unsigned(O_PC)));
                wait until O_PC'event;
            end if;
        end loop;
        
        wait;
    end process;
    
    -- This process handles the memory signals
    mem_proc : process(O_Mem_Write)
    begin
        I_write <= O_Mem_Write;
        Address <= O_Mem_Address;
        I_data <= O_Mem_Data;
    end process;
end Behavior;
