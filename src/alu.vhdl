library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ALU is
    port (
        A      : in std_logic_vector(31 downto 0);
        B      : in std_logic_vector(31 downto 0);
        Op     : in std_logic_vector(2 downto 0);
        B_Inv  : in std_logic;
        Zero   : out std_logic;
        Result : out std_logic_vector(31 downto 0)
    );
end ALU;

architecture Behavior of ALU is
begin
    process (A, B, Op, B_Inv)
    begin
        case Op is
            -- ADD
            when "000" =>
                if B_Inv = '1' then
                    Result <= std_logic_vector(signed(A) - signed(B));
                else
                    Result <= std_logic_vector(unsigned(A) + unsigned(B));
                end if;
            
            -- SLL
            when "001" =>
                Result <= std_logic_vector(shift_left(unsigned(A), to_integer(unsigned(B))));
            
            -- SLT
            when "010" =>
                if signed(A) < signed(B) then
                    Result <= X"00000001";
                else
                    Result <= X"00000000";
                end if;
            
            -- SLTU
            when "011" =>
                if unsigned(A) < unsigned(B) then
                    Result <= X"00000001";
                else
                    Result <= X"00000000";
                end if;
            
            -- XOR
            when "100" =>
                Result <= A xor B;
            
            -- SRL/SRA
            -- SRA if B_Inv = 1
            when "101" =>
                if B_Inv = '1' then
                    Result <= std_logic_vector(shift_right(signed(A), to_integer(unsigned(B))));
                else
                    Result <= std_logic_vector(shift_right(unsigned(A), to_integer(unsigned(B))));
                end if;
            
            -- OR
            when "110" =>
                Result <= A or B;
            
            -- AND
            when "111" =>
                Result <= A and B;
            
            -- Who knows...
            when others =>
        end case;
    end process;
end Behavior;
