library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;
USE std.textio.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;

use work.convolution_pkg.ALL;


architecture top_tb of test is
  component top is
  generic(padding_d  :integer := padding_dim;
	           img_d :integer := img_dim;
             k_d  :integer := kernel_dim);
             
             
--if we want to test in the testbench, we need an input en signal
  port (clk, reset: IN std_logic;
          ready: OUT std_logic);
  end component;

  signal clk, reset, ready: std_logic := '0';
  begin
    
    top_inst: top
          port map(
            clk => clk,
            reset => reset,
            ready => ready
          );
    
    reset <= '1' after 2 ns, '0' after 4 ns;
    clk <= not clk after 10 ns;
    
    

end top_tb;