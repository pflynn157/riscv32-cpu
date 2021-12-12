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
    
    -- Opcodes
    constant NOP : std_logic_vector := X"00000000";
    constant ALU_I_OP : std_logic_vector := "0010011";
    constant ALU_R_OP : std_logic_vector := "0110011";
    constant STORE_OP : std_logic_vector := "0100011";
    constant LOAD_OP : std_logic_vector := "0000011";
    constant BR_OP : std_logic_vector := "1100011";
    constant ALU_ADD : std_logic_vector := "000";
    constant ALU_XOR : std_logic_vector := "100";
    constant ALU_OR  : std_logic_vector := "110";
    constant ALU_AND : std_logic_vector := "111";
    constant X0 : std_logic_vector := "00000";
    constant X1 : std_logic_vector := "00001";
    constant X2 : std_logic_vector := "00010";
    constant X3 : std_logic_vector := "00011";
    constant X4 : std_logic_vector := "00100";
    
    -- Our test programs
    constant SIZE1 : integer := 17;
    type instr_memory1 is array (0 to (SIZE1 - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory1 : instr_memory1 := (
        "0000000" & X0 & X0 & ALU_ADD & X1 & ALU_R_OP,    --[ 0] ADD X1, X0, X0  -> i
        "000000001010" & X0 & ALU_ADD & X2 & ALU_I_OP,    --[ 1] ADDI X2, X0, 10  -> MAX
        "0000000" & X0 & X0 & ALU_ADD & X3 & ALU_R_OP,    --[ 2] ADD X3, X0, X0
        NOP,                                              --[ 3] NOP
        "0000000" & X0 & X3 & "010" & "00000" & STORE_OP, --[ 4] SW X3, [X0, 0]
        NOP,                                              --[ 5] NOP
        "0000000" & X2 & X1 & "101" & "01001" & BR_OP,    --[ 6] BGE X1, X2, 9
        "000000000000" & X0 & "010" & X3 & LOAD_OP,       --[ 7] LW X3, [X0, 0]
        NOP,                                              --[ 8] NOP
        "0000000" & X1 & X3 & ALU_ADD & X3 & ALU_R_OP,    --[ 9] ADD X3, X3, X1
        NOP,                                              --[10] NOP
        "0000000" & X0 & X3 & "010" & "00000" & STORE_OP, --[11] SW X3, [X0, 0]
        "000000000001" & X1 & ALU_ADD & X1 & ALU_I_OP,    --[12] ADDI X1, X1, 1
        NOP,                                              --[13] NOP
        "1111111" & X0 & X0 & "000" & "10111" & BR_OP,    --[14] BEQ X0, X0, -7
        "0000000" & X0 & X0 & ALU_ADD & X1 & ALU_R_OP,    --[15] ADD X1, X0, X0
        "0000000" & X0 & X0 & ALU_ADD & X2 & ALU_R_OP     --[16] ADD X2, X0, X0
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
        --Reg_Check("00001", X"00000005", "Debug failed-> Invalid register X1");
        --Reg_Check("00010", X"00000007", "Debug failed-> Invalid register X2");
        --Reg_Check("00011", X"0000000A", "Debug failed-> Invalid register X3");
        --Reg_Check("00111", X"00000000", "Debug failed-> Invalid register X7");
        
        -- Reset the CPU
        En_Debug <= '0';
        CPU_Reset;
        
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
