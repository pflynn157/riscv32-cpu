library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity cpu_tb1 is
end cpu_tb1;

architecture Behavior of cpu_tb1 is

    -- Declare the CPU component
    component CPU is
        port (
            clk           : in std_logic;
            Reset         : in std_logic;
            I_instr       : in std_logic_vector(31 downto 0);
            O_PC          : out std_logic_vector(31 downto 0);
            O_Mem_Write   : out std_logic;
            O_Mem_Read    : out std_logic;
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
    signal O_Mem_Write, O_Mem_Read : std_logic := '0';
    
    -- Debug signals
    signal En_Debug : std_logic := '0';
    signal DB_Reg_Sel : std_logic_vector(4 downto 0) := "00000";
    signal DB_Data : std_logic_vector(31 downto 0) := X"00000000";
    
    -- Memory signals
    signal Mem_Test : integer := 0;
    signal I_write : std_logic := '0';
    signal data_len : std_logic_vector(1 downto 0) := "00";
    signal address, I_data, O_data : std_logic_vector(31 downto 0) := X"00000000";
    
    -- Opcodes
    constant NOP : std_logic_vector := X"00000000";
    constant ALU_I_OP : std_logic_vector := "0010011";
    constant ALU_R_OP : std_logic_vector := "0110011";
    constant STORE_OP : std_logic_vector := "0100011";
    constant ALU_ADD : std_logic_vector := "000";
    constant ALU_XOR : std_logic_vector := "100";
    constant ALU_OR  : std_logic_vector := "110";
    constant ALU_AND : std_logic_vector := "111";
    
    -- Our test programs
    constant SIZE1 : integer := 3;
    type instr_memory1 is array (0 to (SIZE1 - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory1 : instr_memory1 := (
        "000000000101" & "00000" & ALU_ADD & "00001" & ALU_I_OP,   -- ADDI X1, X0, 5
        "000000000110" & "00000" & ALU_ADD & "00010" & ALU_I_OP,   -- ADDI X2, X0, 6
        "000000001010" & "00010" & ALU_ADD & "00011" & ALU_I_OP    -- ADDI X3, X2, 10
    );
    
    -- Register contents:
    -- X1: 5 | X2: 6 | X3: 16
    
    constant SIZE2 : integer := 11;
    type instr_memory2 is array (0 to (SIZE2 - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory2 : instr_memory2 := (
        "000000000011" & "00001" & ALU_XOR & "00101" & ALU_I_OP,   -- XORI X5, X1, 3 == 6
        "000000000101" & "00001" & ALU_AND & "00110" & ALU_I_OP,   -- ANDI X6, X1, 5 == 5
        "000000001010" & "00001" & ALU_OR & "00111" & ALU_I_OP,    -- ORI  X7, X1, 10 == 15
        "000000000011" & "00000" & ALU_ADD & "00010" & ALU_I_OP,   -- ADDI X2, X0, 3
        "000000000101" & "00000" & ALU_ADD & "00011" & ALU_I_OP,   -- ADDI X3, X0, 5
        "000000001010" & "00000" & ALU_ADD & "00100" & ALU_I_OP,   -- ADDI X4, X0, 10
        "0000000" & "00001" & "00010" & ALU_ADD & "01000" & ALU_R_OP,   -- ADD X8, X2, X1 (X8 == 8)
        "0100000" & "00010" & "00001" & ALU_ADD & "01001" & ALU_R_OP,   -- SUB X9, X1, X2 (X9 == 2)
        "0000000" & "00010" & "00001" & ALU_XOR & "01010" & ALU_R_OP,   -- XOR X10, X1, X2 (X10 == 6)
        "0000000" & "00011" & "00001" & ALU_AND & "01011" & ALU_R_OP,   -- AND X11, X1, X3 (X11 == 5)
        "0000000" & "00100" & "00001" & ALU_OR & "01100" & ALU_R_OP     -- OR X12, X1, X4 (X12 == 15)
    );
    
    -- This contains the memory test
    constant SIZE3 : integer := 15;
    type instr_memory3 is array (0 to (SIZE3 - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory3 : instr_memory3 := (
        "000000000101" & "00000" & ALU_ADD & "00010" & ALU_I_OP,   -- ADDI X2, X0, 5
        "000000001000" & "00000" & ALU_ADD & "00011" & ALU_I_OP,   -- ADDI X3, X0, 8
        "000000100000" & "00000" & ALU_ADD & "00001" & ALU_I_OP,   -- ADDI X1, X0, 16
        "101111001101" & "00000" & ALU_ADD & "00100" & ALU_I_OP,   -- ADDI X4, X0, 0xBCD = 1011 1100 1101
        NOP,
        "0000000" & "00000" & "00100" & ALU_ADD & "00101" & ALU_R_OP,   -- ADD X5, X4, X0
        NOP,
        "00000000" & X"FFA" & "00101" & "0110111",                  -- LUI X5, 0xFFA
        "0000000" & "00000" & "00010" & "000" & "00000" & STORE_OP, -- SB X2, [X0, 0]
        "0000000" & "00000" & "00011" & "000" & "00100" & STORE_OP, -- SB X3, [X0, 4],
        NOP,
        "0000000" & "00001" & "00010" & "000" & "00000" & STORE_OP, -- SB X2, [X1, 0]
        "0000000" & "00001" & "00100" & "001" & "00001" & STORE_OP, -- SH X4, [X1, 1]
        NOP,
        "0000000" & "00001" & "00101" & "010" & "00011" & STORE_OP  -- SW X5, [X1, 3]
    );
begin
    uut : CPU port map (
        clk => clk,
        Reset => Reset,
        I_instr => I_instr,
        O_PC => O_PC,
        O_Mem_Write => O_Mem_Write,
        O_Mem_Read => O_Mem_Read,
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
        
        procedure Mem_Check(Test_Num : in integer; Exp_Data : in std_logic_vector(31 downto 0); message : String) is
        begin
            Mem_Test <= Test_Num;
            wait for clk_period;
            assert O_Data = Exp_Data report message severity warning;
        end Mem_Check;
    begin
        -- Reset the CPU
        --CPU_Reset;
        
        I_instr <= rom_memory1(0);
        wait until O_PC'event;
        for i in 1 to SIZE1 loop
            if to_integer(unsigned(O_PC)) < SIZE1 then
                I_instr <= rom_memory1(to_integer(unsigned(O_PC)));
                wait until O_PC'event;
            end if;
        end loop;
        wait for clk_period * 4;
        
        -- Enter debug mode
        En_Debug <= '1';
        Reg_Check("00000", X"00000000", "Debug failed-> Invalid register X0");
        Reg_Check("00001", X"00000005", "Debug failed-> Invalid register X1");
        Reg_Check("00010", X"00000006", "Debug failed-> Invalid register X2");
        Reg_Check("00011", X"00000010", "Debug failed-> Invalid register X3");
        
        -- Reset the CPU
        En_Debug <= '0';
        CPU_Reset;
        
        -- Run the second program
        for i in 0 to (SIZE2 - 1) loop
            I_instr <= rom_memory2(i);
            wait until O_PC'event;
        end loop;
        wait for clk_period * 6;
        
        -- Enter debug mode
        -- Check: X5 == 6, X6 == 5, X7 == 15, X8 == 8
        --       X10 == 6, X11 = 5, X12 = 15
        En_Debug <= '1';
        Reg_Check("00001", X"00000005", "Debug failed-> Invalid register X1");
        Reg_Check("00101", X"00000006", "Debug failed-> Invalid register X5");
        Reg_Check("00110", X"00000005", "Debug failed-> Invalid register X6");
        Reg_Check("00111", X"0000000F", "Debug failed-> Invalid register X7");
        Reg_Check("01000", X"00000008", "Debug failed-> Invalid register X8");
        Reg_Check("01001", X"00000002", "Debug failed-> Invalid register X9");
        Reg_Check("01010", X"00000006", "Debug failed-> Invalid register X10");
        Reg_Check("01011", X"00000005", "Debug failed-> Invalid register X11");
        Reg_Check("01100", X"0000000F", "Debug failed-> Invalid register X12");
        
        -- Reset the CPU
        En_Debug <= '0';
        CPU_Reset;
        
        -- Run the third program
        for i in 0 to (SIZE3 - 1) loop
            I_instr <= rom_memory3(i);
            wait until O_PC'event;
        end loop;
        wait for clk_period * 6;
        
        -- Enter debug mode
        En_Debug <= '1';
        Reg_Check("00100", X"00000BCD", "Debug failed-> Invalid register X4 (!= 0xBCD)");
        Reg_Check("00101", X"00FFABCD", "Debug failed-> Invalid register X5 (!= OXFFABCD)");
        Mem_Check(1, X"00000005", "Mem[0][0] invalid");
        Mem_Check(2, X"00000008", "Mem[0][4] invalid");
        Mem_Check(3, X"00000005", "Mem[2][0] invalid");
        Mem_Check(4, X"00000BCD", "Mem[2][1] invalid");
        Mem_Check(5, X"00FFABCD", "Mem[2][3] invalid");
        
        wait;
    end process;
    
    -- This process handles the memory signals
    mem_proc : process(O_Mem_Read, O_Mem_Write, O_Mem_Address, O_Mem_Data, O_Data, Mem_Test)
    begin
        if Mem_Test = 0 then
            I_write <= O_Mem_Write;
            Address <= O_Mem_Address;
            I_data <= O_Mem_Data;
            data_len <= O_Data_Len;
            if O_Mem_Read = '1' then
                I_Mem_Data <= O_Data;
            end if;
        else
            I_write <= '0';
            -- TODO: We need a better way to test this
            case Mem_Test is
                when 1 =>
                    Address <= X"00000000";
                    Data_Len <= "00";
                when 2 =>
                    Address <= X"00000004";
                    Data_Len <= "00";
                when 3 =>
                    Address <= X"00000020";
                    Data_Len <= "00";
                when 4 =>
                    Address <= X"00000021";
                    Data_Len <= "01";
                when 5 =>
                    Address <= X"00000023";
                    Data_Len <= "11";
                    
                when others =>
            end case;
        end if;
    end process;
end Behavior;
