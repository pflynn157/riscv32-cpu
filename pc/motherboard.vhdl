library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Motherboard is
    port (
        clk      : in std_logic;
        Dsp_Data : out std_logic_vector(31 downto 0)    -- Data to be displayed by the monitor
    );
end Motherboard;

architecture Behavior of Motherboard is

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
    
    -- Opcodes
    constant NOP : std_logic_vector := X"00000000";
    constant ALU_I_OP : std_logic_vector := "0010011";
    constant ALU_R_OP : std_logic_vector := "0110011";
    constant STORE_OP : std_logic_vector := "0100011";
    constant LOAD_OP : std_logic_vector := "0000011";
    constant BR_OP : std_logic_vector := "1100011";
    constant OUT_OP : std_logic_vector := "0000111";
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
    
    -- The ROM
    -- This would be equivalent to the BIOS
    constant ROM_SIZE : integer := 7;
    type instr_memory is array (0 to (ROM_SIZE - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory : instr_memory := (
        "001111100001" & X0 & ALU_ADD & X1 & ALU_I_OP,        --[ 0] ADDI X1, X0, 1
        "000000011111" & X0 & ALU_ADD & X2 & ALU_I_OP,        --[ 1] ADDI X2, X0, 32
        "111111111011" & X0 & ALU_ADD & X3 & ALU_I_OP,        --[ 2] ADDI X3, X0, -5
        "0000000" & X0 & X2 & "010" & "00000" & STORE_OP,     --[ 3] SW X2, [X0, 0]
        NOP,                                                  --[ 4] NOP
        "000000000000" & X2 & "000" & X1 & OUT_OP,            --[ 5] OUT X1, X2    (Port: 0x01, Cmd: 31 [test command])
        NOP                                                   --[ 6] NOP
    );
begin
    cpu_uut : CPU port map (
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
    
    -- The clock process
    process(clk)
    begin
        	if rising_edge(clk) and (not is_X(O_PC)) and to_integer(unsigned(O_PC)) < ROM_SIZE then
	    	    I_instr <= rom_memory(to_integer(unsigned(O_PC)));
	    end if;
    end process;
    
    -- The main memory process
    process(O_Mem_Read, O_Mem_Write, O_Mem_SX, O_Mem_Address, O_Mem_Data, O_Data)
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
    
    -- The IO process
    process(O_IO_Port, O_IO_Cmd, O_IO_Data, I_IO_Data)
    begin
        if O_IO_Port = "00001" then
            if O_IO_Cmd = "11111" then
                Dsp_Data <= X"4869210A";
            end if;
        end if;
    end process;
end Behavior;
