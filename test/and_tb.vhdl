library ieee;
use ieee.std_logic_1164.all;

entity and_tb is
end and_tb;

architecture behavior of and_tb is
    -- Declare our component
    component AND2
        port(clk, A, B : in std_logic; F : out std_logic);
    end component;
    
    -- Bind to the component
    signal clk, A, B, F : std_logic := '0';
    
    -- Clock period definitions
    constant clk_period : time := 10 ns;
begin
    -- Initialize component
    uut: AND2 port map(clk => clk, A => A, B => B, F => F);
    
    -- Clock process definitions
    I_clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
 
    -- Test process
    stim_proc: process
    begin
        -- hold reset state for 100 ns.
        wait for 100 ns;  

        wait for clk_period*10;
        
        for i in 0 to 3 loop
            A <= '0';
            B <= '0';
            wait for clk_period;
            
            A <= '0';
            B <= '1';
            wait for clk_period;
            
            A <= '1';
            B <= '0';
            wait for clk_period;
            
            A <= '1';
            B <= '1';
            wait for clk_period;
            
            A <= '0';
            B <= '0';
            wait for clk_period;
        end loop;
        
        wait;
        
    end process;
end architecture;

