library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.std_logic_textio.all;

entity pc_tb is
end pc_tb;

architecture Behavior of pc_tb is

    -- Declare the CPU component
    component CPU is
        port (
            clk           : in std_logic;
            Reset         : in std_logic;
            I_instr       : in std_logic_vector(31 downto 0);
            O_PC          : out std_logic_vector(31 downto 0);
            O_Mem_Write   : out std_logic;
            O_Mem_Read    : out std_logic;
            O_Mem_SX      : out std_logic;
            O_Mem_Address : out std_logic_vector(31 downto 0);
            O_Mem_Data    : out std_logic_vector(31 downto 0);
            O_Data_Len    : out std_logic_vector(1 downto 0);
            I_Mem_Data    : in std_logic_vector(31 downto 0);
            O_IO_Port     : out std_logic_vector(4 downto 0);
            O_IO_Cmd      : out std_logic_vector(4 downto 0);
            O_IO_Data     : out std_logic_vector(31 downto 0);
            I_IO_Data     : in std_logic_vector(31 downto 0);
            En_Debug      : in std_logic;
            DB_Reg_Sel    : in std_logic_vector(4 downto 0);
            DB_Data       : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- Declare the memory component
    component Memory is
        port (
            clk      : in std_logic;
            I_write  : in std_logic;
            sx       : in std_logic;
            data_len : in std_logic_vector(1 downto 0);
            address  : in std_logic_vector(31 downto 0);
            I_data   : in std_logic_vector(31 downto 0);
            O_data   : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- The clock signals
    signal clk : std_logic := '0';
    constant clk_period : time := 5 ns;
    
    -- The other signals
    signal Reset : std_logic := '0';
    signal I_instr, O_PC, O_Mem_Address, O_Mem_Data, I_Mem_Data : std_logic_vector(31 downto 0) := X"00000000";
    signal O_Data_Len : std_logic_vector(1 downto 0) := "00";
    signal O_Mem_Write, O_Mem_Read, O_Mem_SX : std_logic := '0';
    
    -- Debug signals
    signal En_Debug : std_logic := '0';
    signal DB_Reg_Sel : std_logic_vector(4 downto 0) := "00000";
    signal DB_Data : std_logic_vector(31 downto 0) := X"00000000";
    
    -- Memory signals
    signal I_write, SX : std_logic := '0';
    signal data_len : std_logic_vector(1 downto 0) := "00";
    signal address, I_data, O_data : std_logic_vector(31 downto 0) := X"00000000";
    
    -- IO signals
    signal O_IO_Port, O_IO_Cmd : std_logic_vector(4 downto 0) := "00000";
    signal I_IO_Data, O_IO_Data : std_logic_vector(31 downto 0) := X"00000000";
    
    -- Our test programs
    constant SIZE1 : integer := 100;
    type instr_memory1 is array (0 to (SIZE1 - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory1 : instr_memory1;
begin
    uut : CPU port map (
        clk => clk,
        Reset => Reset,
        I_instr => I_instr,
        O_PC => O_PC,
        O_Mem_Write => O_Mem_Write,
        O_Mem_Read => O_Mem_Read,
        O_Mem_SX => O_Mem_SX,
        O_Mem_Address => O_Mem_Address,
        O_Mem_Data => O_Mem_Data,
        O_Data_Len => O_Data_Len,
        I_Mem_Data => I_Mem_Data,
        O_IO_Port => O_IO_Port,
        O_IO_Cmd => O_IO_Cmd,
        O_IO_Data => O_IO_Data,
        I_IO_Data => I_IO_Data,
        En_Debug => En_Debug,
        DB_Reg_Sel => DB_Reg_Sel,
        DB_Data => DB_Data
    );
    
    -- Connect memory
    mem_uut : Memory port map(
        clk => clk,
        I_write => I_write,
        SX => SX,
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
        file input : text open read_mode is "../sata0.txt";
        variable read_line : line;
        variable data : std_logic_vector(31 downto 0) := X"00000000";
        variable index : integer := 0;
    begin
        -- Load the program
        Reset <= '1';
        while not endfile(input) loop
            readline(input, read_line);
            read(read_line, data);
            rom_memory1(index) <= data;
            index := index + 1;
        end loop;
        file_close(input);
        wait for clk_period * 2;
        Reset <= '0';
        wait for clk_period;
    
        -- Run program 1
        I_instr <= rom_memory1(0);
        wait until O_PC'event;
        while to_integer(unsigned(O_PC)) < SIZE1 loop
            I_instr <= rom_memory1(to_integer(unsigned(O_PC)));
            wait until O_PC'event;
        end loop;
        wait for clk_period * 4;
        
        -- Reset
       Reset <= '1';
       wait for clk_period * 2;
        
        wait;
    end process;
    
    -- This process handles the memory signals
    mem_proc : process(O_Mem_Read, O_Mem_Write, O_Mem_SX, O_Mem_Address, O_Mem_Data, O_Data)
    begin
        I_write <= O_Mem_Write;
        SX <= O_Mem_SX;
        Address <= O_Mem_Address;
        I_data <= O_Mem_Data;
        data_len <= O_Data_Len;
        if O_Mem_Read = '1' then
            I_Mem_Data <= O_Data;
        end if;
    end process;
end Behavior;
