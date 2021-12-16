library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity slt_tb is
end slt_tb;

architecture Behavior of slt_tb is

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
    constant ALU_SLL : std_logic_vector := "001";
    constant ALU_SLT : std_logic_vector := "010";
    constant ALU_SLTU : std_logic_vector := "011";
    constant ALU_XOR : std_logic_vector := "100";
    constant ALU_SRL : std_logic_vector := "101";
    constant ALU_OR  : std_logic_vector := "110";
    constant ALU_AND : std_logic_vector := "111";
    constant X0 : std_logic_vector := "00000";
    constant X1 : std_logic_vector := "00001";
    constant X2 : std_logic_vector := "00010";
    constant X3 : std_logic_vector := "00011";
    constant X4 : std_logic_vector := "00100";
    constant X5 : std_logic_vector := "00101";
    constant X6 : std_logic_vector := "00110";
    constant X7 : std_logic_vector := "00111";
    constant X8 : std_logic_vector := "01000";
    constant X9 : std_logic_vector := "01001";
    constant X10 : std_logic_vector := "01010";
    constant X11 : std_logic_vector := "01011";
    
    -- Our test programs
    constant SIZE1 : integer := 23;
    type instr_memory1 is array (0 to (SIZE1 - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory1 : instr_memory1 := (
        "000000000011" & X0 & ALU_ADD & X1 & ALU_I_OP,    --[ 0] ADDI X1, X0, 3
        "000000000100" & X0 & ALU_ADD & X2 & ALU_I_OP,    --[ 1] ADDI X2, X0, 4
        "111111111011" & X0 & ALU_ADD & X3 & ALU_I_OP,    --[ 2] ADDI X3, X0, -5
        "000000000010" & X0 & ALU_ADD & X4 & ALU_I_OP,    --[ 3] ADDI X4, X0, 2
        "000000000010" & X0 & ALU_ADD & X5 & ALU_I_OP,    --[ 4] ADDI X5, X0, 2
        "000000000010" & X0 & ALU_ADD & X6 & ALU_I_OP,    --[ 5] ADDI X6, X0, 2
        "000000000010" & X0 & ALU_ADD & X7 & ALU_I_OP,    --[ 6] ADDI X7, X0, 2
        "000000000010" & X0 & ALU_ADD & X8 & ALU_I_OP,    --[ 7] ADDI X8, X0, 2
        "000000000010" & X0 & ALU_ADD & X9 & ALU_I_OP,    --[ 8] ADDI X9, X0, 2
        "000000000010" & X0 & ALU_ADD & X10 & ALU_I_OP,   --[ 9] ADDI X10, X0, 2
        "000000000010" & X0 & ALU_ADD & X11 & ALU_I_OP,   --[10] ADDI X11, X0, 2
        NOP,											  --[11] NOP
        "0000000" & X2 & X1 & ALU_SLT & X4 & ALU_R_OP,    --[12] SLT X4, X1, X2  (X4 == 1)
        "0000000" & X1 & X2 & ALU_SLT & X5 & ALU_R_OP,    --[13] SLT X5, X2, X1  (X5 == 0)
        "0000000" & X1 & X3 & ALU_SLT & X6 & ALU_R_OP,    --[14] SLT X6, X3, X1  (X6 == 1)
        "0000000" & X1 & X3 & ALU_SLTU & X7 & ALU_R_OP,   --[15] SLTU X7, X3, X1  (X7 == 0)
        NOP,											  --[16] NOP
        NOP,											  --[17] NOP
        "000000000100" & X1 & ALU_SLT & X8 & ALU_I_OP,    --[18] SLTI X8, X1, 4		(X8 == 1)
        "000000000011" & X2 & ALU_SLT & X9 & ALU_I_OP,    --[19] SLTI X9, X2, 3  	(X9 == 0)
        "000000000011" & X3 & ALU_SLT & X10 & ALU_I_OP,   --[20] SLTI X10, X3, 3		(X10 == 1)
        "000000000011" & X3 & ALU_SLTU & X11 & ALU_I_OP,  --[21] SLTIU X11, X3, 3	(X11 == 0)
        NOP 											  --[22] NOP
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
        Reg_Check(X1, X"00000003", "Debug failed-> Invalid register X1");
        Reg_Check(X2, X"00000004", "Debug failed-> Invalid register X2");
        Reg_Check(X3, X"FFFFFFFB", "Debug failed-> Invalid register X3");
        Reg_Check(X4, X"00000001", "Debug failed-> Invalid register X4");
        Reg_Check(X5, X"00000000", "Debug failed-> Invalid register X5");
        Reg_Check(X6, X"00000001", "Debug failed-> Invalid register X6");
        Reg_Check(X7, X"00000000", "Debug failed-> Invalid register X7");
        Reg_Check(X8, X"00000001", "Debug failed-> Invalid register X8");
        Reg_Check(X9, X"00000000", "Debug failed-> Invalid register X9");
        Reg_Check(X10, X"00000001", "Debug failed-> Invalid register X10");
        Reg_Check(X11, X"00000000", "Debug failed-> Invalid register X11");
        
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
