library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CPU is
    port (
        clk           : in std_logic;
        I_instr       : in std_logic_vector(31 downto 0);
        O_PC          : out std_logic_vector(31 downto 0);
        O_Mem_Write   : out std_logic;
        O_Mem_Address : out std_logic_vector(31 downto 0);
        O_Mem_Data    : out std_logic_vector(31 downto 0)
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
    
    -- The register file
    component Registers is
        port (
            clk     : in std_logic;
            sel_A   : in std_logic_vector(4 downto 0);
            sel_B   : in std_logic_vector(4 downto 0);
            sel_D   : in std_logic_vector(4 downto 0);
            I_dataD : in std_logic_vector(31 downto 0);
            I_enD   : in std_logic;
            O_dataA : out std_logic_vector(31 downto 0);
            O_dataB : out std_logic_vector(31 downto 0)
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
    signal A, B, Result: std_logic_vector(31 downto 0);
    signal ALU_Op : std_logic_vector(2 downto 0);
    signal B_Inv, Zero : std_logic := '0';
    
    -- Signals for the register file component
    signal sel_A, sel_B, sel_D : std_logic_vector(4 downto 0);
    signal I_dataD, O_dataA, O_dataB : std_logic_vector(31 downto 0);
    signal I_enD : std_logic;
    
    -- Intermediate signals for the pipeline
    signal sel_D_1, sel_D_2 : std_logic_vector(4 downto 0);
    signal srcImm, RegWrite, MemWrite : std_logic := '0';
    signal Imm_S2 : std_logic_vector(11 downto 0);

    -- Pipeline and program counter signals
    signal PC : std_logic_vector(31 downto 0) := X"00000000";
    signal IF_stall, MEM_stall : std_logic := '0';
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
    
    -- Connect the registers
    uut_Registers : Registers port map (
        clk => clk,
        sel_A => sel_A,
        sel_B => sel_B,
        sel_D => sel_D,
        I_dataD => I_dataD,
        I_enD => I_enD,
        O_dataA => O_dataA,
        O_dataB => O_dataB
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
                    sel_D_1 <= rd;
                    sel_A <= rs1;
                    sel_B <= rs2;
                    srcImm <= '0';
                    RegWrite <= '0';
                    MemWrite <= '0';
                    
                    Imm_S2 <= Imm;
                    
                    case opcode is
                        -- ALU instructions
                        when "0010011" | "0110011" =>
                            ALU_op <= funct3;
                            RegWrite <= '1';
                            if opcode(5) = '0' then
                                srcImm <= '1';
                            end if;
                            
                        -- Store instructions
                        when "0100011" =>
                            Imm_S2 <= Imm2 & Imm1;
                            ALU_Op <= "000";
                            sel_A <= rs2;
                            sel_B <= rs1;
                            srcImm <= '1';
                            MemWrite <= '1';
                            Mem_Stall <= '1';
                        
                        -- TODO: We should probably generate some sort of fault here...
                        when others =>
                    end case;
                    
                    -- Check to see if we have a RAW dependency. If so, stall the pipeline
                    if rd = sel_A or rd = sel_B then
                        IF_stall <= '1';
                    end if;
                elsif stage = 2 and IF_stall = '1' then
                    IF_stall <= '0';
                
                -- Instruction execute
                elsif stage = 3 then
                    sel_D_2 <= sel_D_1;
                    
                    A <= O_dataA;
                    if srcImm = '1' then
                        B <= "00000000000000000000" & Imm_S2;
                    else
                        B <= O_dataB;
                    end if;
                
                -- Memory
                elsif stage = 4 and Mem_Stall = '0' then
                    O_Mem_Write <= MemWrite;
                    if MemWrite = '1' then
                        O_Mem_Address <= Result;
                        O_Mem_Data <= O_dataB;
                    end if;
                elsif stage = 4 and Mem_Stall = '1' then
                    Mem_Stall <= '0';
                
                -- Write-back
                elsif stage = 5 then
                    if RegWrite = '1' then
                        sel_D <= sel_D_2;
                        I_dataD <= Result;
                        I_enD <= '1';
                    else
                        I_enD <= '0';
                    end if;
                    
                    -- Prepare for instrution fetch on next cycle
                    O_PC <= PC;
                end if;
            end loop;
        end if;
    end process;
end Behavior;