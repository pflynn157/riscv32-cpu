library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CPU is
    port (
        clk     : in std_logic;
        I_instr : in std_logic_vector(31 downto 0);
        O_PC    : out std_logic_vector(31 downto 0)
    );
end CPU;

architecture Behavior of CPU is

    -- The decoder component
    component Decoder is
        port (
            instr  : in std_logic_vector(31 downto 0);
            opcode : out std_logic_vector(6 downto 0);
            rd     : out std_logic_vector(4 downto 0);
            rs1    : out std_logic_vector(4 downto 0);
            rs2    : out std_logic_vector(4 downto 0);
            funct3 : out std_logic_vector(2 downto 0);
            funct7 : out std_logic_vector(6 downto 0);
            imm    : out std_logic_vector(11 downto 0);
            imm1   : out std_logic_vector(4 downto 0);
            imm2   : out std_logic_vector(6 downto 0);
            UJ_imm : out std_logic_vector(19 downto 0)
        );
    end component;
    
    -- Signals for the decoder component
    signal instr : std_logic_vector(31 downto 0);
    signal opcode, funct7, imm2 : std_logic_vector(6 downto 0);
    signal rd, rs1, rs2, imm1 : std_logic_vector(4 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal imm : std_logic_vector(11 downto 0);
    signal UJ_imm : std_logic_vector(19 downto 0);

    -- Pipeline and program counter signals
    signal stage : integer := 1;
    signal PC : std_logic_vector(31 downto 0) := X"00000000";
begin
    -- Connect the decoder
    uut_decoder : Decoder port map (
        instr => instr,
        opcode => opcode,
        rd => rd,
        rs1 => rs1,
        rs2 => rs2,
        funct3 => funct3,
        funct7 => funct7,
        imm => imm,
        imm1 => imm1,
        imm2 => imm2,
        UJ_imm => UJ_imm
    );

    process (clk)
    begin
        if rising_edge(clk) then
            case stage is
                when 1 =>
                    PC <= std_logic_vector(unsigned(PC) + 1);
                    instr <= I_instr;
                    stage <= 2;
                    
                -- Decode
                when 2 =>
                
                    stage <= 3;
                    
                -- Execute
                when 3 =>
                    
                    stage <= 4;
                    
                -- Memory
                when 4 =>
                    stage <= 5;
                    
                -- Write-back
                when 5 =>
                    O_PC <= PC;
                    stage <= 1;
                    
                -- Waste electricity
                when others =>
            end case;
        end if;
    end process;
end Behavior;