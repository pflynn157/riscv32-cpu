library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CPU is
    port (
        clk           : in std_logic;
        reset         : in std_logic;
        I_instr       : in std_logic_vector(31 downto 0);
        O_PC          : out std_logic_vector(31 downto 0);
        O_Mem_Write   : out std_logic;
        O_Mem_Read    : out std_logic;
        O_Mem_Sx      : out std_logic;
        O_Mem_Address : out std_logic_vector(31 downto 0);
        O_Mem_Data    : out std_logic_vector(31 downto 0);
        O_Data_Len    : out std_logic_vector(1 downto 0);
        I_Mem_Data    : in std_logic_vector(31 downto 0);
        En_Debug      : in std_logic;                        -- Enables debug for automated testing
        DB_Reg_Sel    : in std_logic_vector(4 downto 0);     -- Select the register
        DB_Data       : out std_logic_vector(31 downto 0)    -- Output the debug data
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
    signal ALU_Op, ALU_Op1 : std_logic_vector(2 downto 0);
    signal B_Inv, B_Inv1, Zero : std_logic := '0';
    
    -- Signals for the register file component
    signal sel_A, sel_B, sel_D : std_logic_vector(4 downto 0);
    signal I_dataD, O_dataA, O_dataB : std_logic_vector(31 downto 0);
    signal I_enD : std_logic;
    
    -- Intermediate signals for the pipeline
    signal sel_D_1, sel_D_2 : std_logic_vector(4 downto 0);
    signal srcImm, RegWrite, RegWrite2, MemWrite, MemWrite2 : std_logic := '0';
    signal MemRead, MemRead2, Mem_SX, Mem_SX2 : std_logic := '0';
    signal MemData, srcImm_In : std_logic_vector(31 downto 0);
    signal Data_Len, Data_Len2 : std_logic_vector(1 downto 0);
    signal Br_Op : std_logic_vector(2 downto 0);
    signal Br : std_logic := '0';
    signal Br_stage : integer := 1;

    -- Pipeline and program counter signals
    signal PC : std_logic_vector(31 downto 0) := X"00000000";
    signal IF_stall, MEM_stall : std_logic := '0';
    signal WB_stall : integer := 0;
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
        -- Debug time!
        if rising_edge(clk) and En_Debug = '1' then
            sel_A <= DB_Reg_Sel;
            DB_Data <= O_dataA;
            
        -- Reset
        elsif rising_edge(clk) and Reset = '1' then
            PC <= X"00000000";
            O_PC <= PC;
            O_Mem_Write <= '0';
            
        -- The branch processor
        -- This has 3 stages 1) R-fetch, math, evaluate
        elsif rising_edge(clk) and Br = '1' then
            -- ALU
            if Br_Stage = 1 then
                ALU_Op <= "000";
                B_Inv <= '1';
                A <= O_dataA;
                B <= O_dataB;
                PC <= std_logic_vector(signed(PC) - 1);
                Br_Stage <= 2;
                
            -- Evaluate
            elsif Br_Stage = 2 then
                case Br_Op is
                    -- BEQ
                    when "000" =>
                        if signed(Result) = 0 then
                            instr <= X"00000000";
                            PC <= std_logic_vector(signed(PC) + signed(SrcImm_In) - 2);
                        end if;
                        
                    -- BNE
                    when "001" =>
                        if signed(Result) /= 0 then
                            instr <= X"00000000";
                            PC <= std_logic_vector(signed(PC) + signed(SrcImm_In) - 2);
                        end if;
                    
                    -- BLT
                    when "100" =>
                        if signed(Result) < 0 then
                            instr <= X"00000000";
                            PC <= std_logic_vector(signed(PC) + signed(SrcImm_In) - 2); 
                        end if;
                    
                    -- BGE
                    when "101" =>
                        if signed(Result) >= 0 then
                            instr <= X"00000000";
                            PC <= std_logic_vector(signed(PC) + signed(SrcImm_In) - 2); 
                        end if;
                    
                    -- BLTU
                    -- BGEU
                    
                    when others =>
                end case;
                
                Br_Stage <= 3;
            
            -- ??
            elsif Br_Stage = 3 then
                O_PC <= PC;
                Br_Stage <= 1;
                Br <= '0';
            end if;
            
        -- The main CPU
        elsif rising_edge(clk) and En_Debug = '0' and Br = '0' then
            for stage in 1 to 5 loop
                -- Instruction fetch
                if stage = 1 and IF_stall = '0' then
                    if opcode = "0000011" then
                        instr <= X"00000000";
                    else
                        PC <= std_logic_vector(unsigned(PC) + 1);
                        instr <= I_instr;
                    end if;
                    
                -- Instruction decode
                elsif stage = 2 and IF_stall = '0' then
                    sel_D_1 <= rd;
                    sel_A <= rs1;
                    sel_B <= rs2;
                    srcImm <= '0';
                    B_Inv1 <= '0';
                    RegWrite <= '0';
                    MemWrite <= '0';
                    Mem_Stall <= '0';
                    MemRead <= '0';
                    Mem_SX <= '0';
                    Br <= '0';
                    
                    case opcode is
                        -- ALU instructions
                        when "0010011" | "0110011" =>
                            ALU_op1 <= funct3;
                            RegWrite <= '1';
                            if opcode(5) = '0' then
                                srcImm_In <= "00000000000000000000" & Imm;
                                srcImm <= '1';
                            end if;
                            
                            -- Check subtraction. We need to make sure we have an R-type
                            -- ALU opcode so we don't accidently set B_Inv based on Imm
                            if opcode(5) = '1' and imm2(5) = '1' then
                                B_Inv1 <= '1';
                            end if;
                            
                        -- LUI instruction
                        when "0110111" =>
                            ALU_op1 <= "000";
                            RegWrite <= '1';
                            sel_A <= rd;
                            srcImm <= '1';
                            srcImm_In <= UJ_Imm & "000000000000";
                            
                        -- Branch instructions
                        when "1100011" =>
                            Br <= '1';
                            srcImm_In <= "00000000000000000000" & Imm2 & Imm1;
                            WB_stall <= 1;
                            Br_Op <= funct3;
                            
                        -- Load instructions
                        when "0000011" =>
                            srcImm_In <= "00000000000000000000" & Imm;
                            ALU_op1 <= "000";
                            srcImm <= '1';
                            MemRead <= '1';
                            WB_Stall <= 2;
                            IF_stall <= '1';
                            RegWrite <= '1';
                            Mem_SX <= not funct3(2);
                            case funct3 is
                                when "000" | "100" => Data_Len <= "00";
                                when "001" | "101" => Data_Len <= "01";
                                when "010" => Data_Len <= "11";
                                when others => Data_Len <= "00";
                            end case;
                            
                        -- Store instructions
                        when "0100011" =>
                            srcImm_In <= "00000000000000000000" & Imm2 & Imm1;
                            ALU_Op1 <= "000";
                            sel_A <= rs2;
                            sel_B <= rs1;
                            srcImm <= '1';
                            MemWrite <= '1';
                            Mem_Stall <= '1';
                            case funct3 is
                                when "000" => Data_Len <= "00";
                                when "001" => Data_Len <= "01";
                                when "010" => Data_Len <= "11";
                                when others => Data_Len <= "00";
                            end case;
                        
                        -- TODO: We should probably generate some sort of fault here...
                        when others =>
                    end case;
                    
                    -- Check to see if we have a RAW dependency. If so, stall the pipeline
                    if opcode = "0100011" then
                    elsif opcode = "0000011" then
                    elsif opcode = "0000000" then
                    else
                        if rd = sel_A then
                            IF_stall <= '1';
                        elsif rd = sel_B and SrcImm = '0' then
                            IF_stall <= '1';
                        end if;
                    end if;
                elsif stage = 2 and IF_stall = '1' then
                    IF_stall <= '0';
                
                -- Instruction execute
                elsif stage = 3 then
                    B_Inv <= B_Inv1;
                    sel_D_2 <= sel_D_1;
                    ALU_Op <= ALU_Op1;
                    MemWrite2 <= MemWrite;
                    MemRead2 <= MemRead;
                    Mem_SX2 <= Mem_SX;
                    RegWrite2 <= RegWrite;
                    MemData <= O_dataB;
                    Data_Len2 <= Data_Len;
                    
                    A <= O_dataA;
                    if srcImm = '1' then
                        B <= srcImm_In;
                    else
                        B <= O_dataB;
                    end if;
                
                -- Memory
                elsif stage = 4 and Mem_Stall = '0' then
                    O_Mem_Write <= MemWrite2;
                    O_Mem_Read <= MemRead2;
                    O_Mem_Address <= Result;
                    O_Data_Len <= Data_Len2;
                    O_Mem_SX <= Mem_SX2;
                    
                    if MemWrite2 = '1' then
                        O_Mem_Data <= MemData;
                    end if;
                elsif stage = 4 and Mem_Stall = '1' then
                    Mem_Stall <= '0';
                
                -- Write-back
                elsif stage = 5 and WB_Stall = 0 then
                    if RegWrite2 = '1' then
                        sel_D <= sel_D_2;
                        I_enD <= '1';
                        
                        if MemRead2 = '1' then
                            I_dataD <= I_Mem_Data;
                        else
                            I_dataD <= Result;
                        end if;
                    else
                        I_enD <= '0';
                    end if;
                    
                    -- Prepare for instrution fetch on next cycle
                    O_PC <= PC;
                elsif stage = 5 and WB_Stall > 0 then
                    WB_Stall <= WB_stall - 1;
                end if;
            end loop;
        end if;
    end process;
end Behavior;
