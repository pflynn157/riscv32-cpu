library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bne_tb is
end bne_tb;

architecture Behavior of bne_tb is

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
    constant clk_period : time := 10 ns;
    
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
    
    -- Our test programs
    constant SIZE1 : integer := 10;
    type instr_memory1 is array (0 to (SIZE1 - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory1 : instr_memory1 := (
        "000000000101" & "00000" & "000" & "00001" & "0010011",         --[0] ADDI X1, X0, 5
        "000000000110" & "00000" & "000" & "00010" & "0010011",         --[1] ADDI X2, X0, 6
        "0000000" & "00010" & "00001" & "001" & "00110" & "1100011",    --[2] BNE X1, X2, 6
        "000000001011" & "00000" & "000" & "00011" & "0010011",         --[3] ADDI X3, X0, 11
        "011011110100" & "00000" & "000" & "00001" & "0010011",         --[4] ADDI X1, X0, 0x6F4
        "011011110100" & "00000" & "000" & "00010" & "0010011",         --[5] ADDI X2, X0, 0x6F4
        "011011110100" & "00000" & "000" & "00011" & "0010011",         --[6] ADDI X3, X0, 0x6F4
        "011011110100" & "00000" & "000" & "00111" & "0010011",         --[7] ADDI X7, X0, 0x6F4
        "000000001010" & "00000" & "000" & "00011" & "0010011",         --[8] ADDI X3, X0, 10
        "000000000111" & "00000" & "000" & "00010" & "0010011"          --[9] ADDI X2, X0, 7
    );
    
    constant SIZE2 : integer := 10;
    type instr_memory2 is array (0 to (SIZE2 - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory2 : instr_memory2 := (
        "000000000101" & "00000" & "000" & "00001" & "0010011",         --[0] ADDI X1, X0, 5
        "000000000110" & "00000" & "000" & "00010" & "0010011",         --[1] ADDI X2, X0, 6
        "0000000" & "00000" & "00000" & "001" & "00110" & "1100011",    --[2] BNE X0, X0, 6
        "000000001011" & "00000" & "000" & "00011" & "0010011",         --[3] ADDI X3, X0, 11
        "011011110100" & "00000" & "000" & "00001" & "0010011",         --[4] ADDI X1, X0, 0x6F4
        "011011110100" & "00000" & "000" & "00010" & "0010011",         --[5] ADDI X2, X0, 0x6F4
        "011011110100" & "00000" & "000" & "00011" & "0010011",         --[6] ADDI X3, X0, 0x6F4
        "011011110100" & "00000" & "000" & "00111" & "0010011",         --[7] ADDI X7, X0, 0x6F4
        "000000001010" & "00000" & "000" & "00011" & "0010011",         --[8] ADDI X3, X0, 10
        "000000000111" & "00000" & "000" & "00010" & "0010011"          --[9] ADDI X2, X0, 7
    );
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
        procedure CPU_Reset is
        begin
            Reset <= '1';
            wait for clk_period * 3;
            Reset <= '0';
            wait for clk_period * 3;
        end CPU_Reset;
        
        procedure Reg_Check(DB_Reg : in std_logic_vector(4 downto 0); Exp_Data : in std_logic_vector(31 downto 0); message : String) is
        begin
            DB_Reg_Sel <= DB_Reg;
            wait for clk_period * 2;
            assert DB_data = Exp_Data report message severity warning;
        end Reg_Check;
    begin
        -- Run program 1
        I_instr <= rom_memory1(0);
        wait until O_PC'event;
        while to_integer(unsigned(O_PC)) < SIZE1 loop
            I_instr <= rom_memory1(to_integer(unsigned(O_PC)));
            wait until O_PC'event;
        end loop;
        wait for clk_period * 4;
        
        -- Enter debug mode
        En_Debug <= '1';
        Reg_Check("00001", X"00000005", "Debug failed-> Invalid register X1");
        Reg_Check("00010", X"00000007", "Debug failed-> Invalid register X2");
        Reg_Check("00011", X"0000000A", "Debug failed-> Invalid register X3");
        Reg_Check("00111", X"00000000", "Debug failed-> Invalid register X7");
        
        -- Reset the CPU
        En_Debug <= '0';
        CPU_Reset;
        
        -- Run program 2
        I_instr <= rom_memory2(0);
        wait until O_PC'event;
        while to_integer(unsigned(O_PC)) < SIZE2 loop
            I_instr <= rom_memory2(to_integer(unsigned(O_PC)));
            wait until O_PC'event;
        end loop;
        wait for clk_period * 4;
        
        -- Enter debug mode
        En_Debug <= '1';
        Reg_Check("00001", X"000006F4", "Debug failed-> Invalid register X1");
        Reg_Check("00010", X"00000007", "Debug failed-> Invalid register X2");
        Reg_Check("00011", X"0000000A", "Debug failed-> Invalid register X3");
        Reg_Check("00111", X"000006F4", "Debug failed-> Invalid register X7");
        
        wait;
    end process;
    
    -- This process handles the memory signals
    mem_proc : process(O_Mem_Read, O_Mem_Write, O_Mem_Address, O_Mem_Data, O_Data)
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
