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
    signal stage : integer := 1;
    signal PC : std_logic_vector(31 downto 0) := X"00000000";
begin
    process (clk)
    begin
        if rising_edge(clk) then
            case stage is
                when 1 =>
                    PC <= std_logic_vector(unsigned(PC) + 1);
                    
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