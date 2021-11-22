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
    
    -- The ALU component
    component ALU is
        port (
            A      : in std_logic_vector(31 downto 0);
            B      : in std_logic_vector(31 downto 0);
            Op     : in std_logic_vector(2 downto 0);
            B_Inv  : in std_logic;
            Zero   : out std_logic;
            Result : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- Signals for the decoder component
    signal instr : std_logic_vector(31 downto 0);
    signal opcode, funct7, imm2 : std_logic_vector(6 downto 0);
    signal rd, rs1, rs2, imm1 : std_logic_vector(4 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal imm : std_logic_vector(11 downto 0);
    signal UJ_imm : std_logic_vector(19 downto 0);
    
    -- Signals for the ALU component
    signal A, B, Result : std_logic_vector(31 downto 0);
    signal ALU_Op : std_logic_vector(2 downto 0);
    signal B_Inv, Zero : std_logic := '0';
    
    -- Intermediate signals for the pipeline
    signal rd_1, rs1_1, rs2_1 : std_logic_vector(4 downto 0);
    signal srcImm : std_logic := '0';

    -- Pipeline and program counter signals
    signal PC : std_logic_vector(31 downto 0) := X"00000000";
    signal IF_stall : std_logic := '0';
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
    
    -- Connect the ALU
    uut_ALU : ALU port map (
        A => A,
        B => B,
        Op => ALU_Op,
        B_Inv => B_Inv,
        Zero => Zero,
        Result => Result
    );

    process (clk)
    begin
        if rising_edge(clk) then
            for stage in 1 to 5 loop
                -- Instruction fetch
                if stage = 1 and IF_stall = '0' then
                    PC <= std_logic_vector(unsigned(PC) + 1);
                    instr <= I_instr;
                    
                -- Instruction decode
                elsif stage = 2 and IF_stall = '0' then
                    rd_1 <= rd;
                    rs1_1 <= rs1;
                    rs2_1 <= rs2;
                    srcImm <= '0';
                    
                    case opcode is
                        -- ALU instructions
                        when "0010011" | "0110011" =>
                            ALU_op <= funct3;
                            if opcode(5) = '0' then
                                srcImm <= '1';
                            end if;
                        
                        -- TODO: We should probably generate some sort of fault here...
                        when others =>
                    end case;
                        
                    if rd = rs1_1 or rd = rs2_1 then
                        IF_stall <= '1';
                    end if;
                elsif stage = 2 and IF_stall = '1' then
                    IF_stall <= '0';
                
                -- Instruction execute
                elsif stage = 3 then
                    if srcImm = '1' then
                        A <= X"00000000";
                        B <= "00000000000000000000" & Imm;
                    else
                    
                    end if;
                
                -- Memory
                elsif stage = 4 then
                
                -- Write-back
                elsif stage = 5 then
                    O_PC <= PC;
                end if;
            end loop;
        end if;
    end process;
end Behavior;