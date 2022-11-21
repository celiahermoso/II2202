library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.convolution_pkg.ALL;

use IEEE.std_logic_arith.all;

entity vec_convolution is
    generic (--padding_d  :integer;
	           --img_d :integer;
             k_d  :integer); -- kernel dimension
    port (clk, en: IN std_logic;
          img_in_1: IN integer_vector (0 to k_d-1); -- input image array
          img_in_2: IN integer_vector (0 to k_d-1);
          img_in_3: IN integer_vector (0 to k_d-1);
          kernel_in: IN integer_vector (0 to (k_d*k_d)-1); -- input kernel array
          ready: OUT std_logic;
          --new_img: OUT integer_vector (0 to (img_d)*(img_d)-1)); -- output image
          new_img: OUT integer);
end vec_convolution;

architecture behavioral of vec_convolution is


--signal krnl: kernel_type(0 to k_d-1, 0 to k_d-1);
--signal img: img_type(0 to padding_d-1, 0 to padding_d-1);
signal rdy: std_logic := '0';

BEGIN   
    --krnl <= kernel_in;
    --img <= img_in;
    ready <= rdy;
    process (clk,en)--,rdy)
    variable sum :integer 	:= 0;
    --variable n_i_width:integer  := padding_d - (k_d - 1);
    --variable n_i_height:integer := padding_d - (k_d - 1);
    begin
    --if(en = '1' and rdy = '0') then
    if(rising_edge(clk))then
    	--for y in 0 to (img_dim-1) loop
	    -- for x in 0 to (img_dim-1) loop
	     --sum :=0;
	      --for k_r in 0 to (k_d-1) loop
		      --for k_c in 0 to (k_d-1) loop
		        --sum := sum + img((y+k_r),(x+k_c)) * krnl(k_r,k_c); 	
		      --end loop;
	      --end loop;
	      --new_img(y*(img_dim)+x) <= sum;
	     --end loop;
      --end loop;
      --rdy <= '1';   
      --end if;
      sum := 0;
      for i in 0 to k_d-1 loop
          sum := sum + img_in_1(i) * kernel_in(i);
          sum := sum + img_in_2(i) * kernel_in(i + k_d);
          sum := sum + img_in_3(i) * kernel_in(i + 2*k_d);
      end loop;
      new_img <= sum;
      rdy <= not rdy;
    end if;
    end process;
end Behavioral;

