library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;
USE std.textio.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;

use work.convolution_pkg.ALL;

entity test is

  
--  constant dog_kernel_2: kernel_type (0 to 4, 0 to 4) := (
--            (0, 0, 0, 0, 0),
--            (0, 0, 10, 0, 0),
--            (0, 10, 231, 10, 0),
--            (0, 0, 10, 0, 0),
--            (0, 0, 0, 0, 0));
  
end entity;


architecture behave of test is
  component convolution is
    generic (--padding_d  :integer  := padding_dim;
	           --img_d :integer  := img_dim;
             k_d  :integer  := kernel_dim);
    port (clk, en: IN std_logic;
          img_in: IN img_type (0 to k_d-1, 0 to k_d-1);
          kernel_in: IN kernel_type (0 to k_d-1, 0 to k_d-1);
          ready: OUT std_logic;
          --new_img: OUT integer_vector (0 to (img_d)*(img_d)-1));
          new_img: OUT integer);
  end component;
  
    
  
  signal clk: std_logic := '0';
  signal output: integer_vector (0 to (img_dim)*(img_dim)-1) := (others => 0);
  signal gauss1, gauss2: integer_vector (0 to (img_dim)*(img_dim)-1) := (others => 0);

  signal input_kernel: kernel_type (0 to kernel_dim-1, 0 to kernel_dim-1) := laplacian_kernel;
  
  signal sig_padded_img: img_type (0 to padding_dim-1, 0 to padding_dim-1) := (others => (others => 0));
  file input_image_file : text open read_mode is input_file_path;
  file output_image_file : text open write_mode is output_file_path;
  type integer_array is array (integer range <>) of integer;
  signal img_proc_flag, padding_flag: std_logic := '0';
  --signal int_i: integer_array(0 to (img_dim*img_dim));
  signal en,ready,done: std_logic := '0';
  
  
  signal new_conv_out: integer := 0;
  signal image_slice: img_type(0 to kernel_dim-1, 0 to kernel_dim -1) := (others => (others => 0));
  
  signal id_x, id_y: integer := 0;
  signal new_hex_out: std_logic_vector(15 downto 0) := (others => '0');
  
begin
  conv: convolution
        port map(
          en => en,
          ready => ready,
          clk => clk,
          --new_img => output,
          new_img => new_conv_out,
          img_in => image_slice,
          kernel_in => input_kernel
        );
        
--  conv2: convolution
--        port map(
--          en => en,
--          ready => ready2,
--          clk => clk,
--          new_img => gauss2,
--          img_in => padded_img,
--          kernel_in => input_kernel2
--        );
        
        
  process(img_proc_flag, padding_flag, ready, done, new_conv_out)
    variable line_i: line;
    variable hex_in: std_logic_vector(7 downto 0) := (others => '0');
    variable hex_out: std_logic_vector(15 downto 0) := (others => '0');
    --variable int_i: integer_array(0 to (128*128));  
    variable idx: integer := 0;
    
    variable padded_img: img_type (0 to padding_dim-1, 0 to padding_dim-1) := (others => (others => 0));
    variable int_i: integer_array(0 to (img_dim*img_dim));
    
    
  begin
    if(img_proc_flag = '0') then
      while not endfile(input_image_file) loop
        readline(input_image_file, line_i);
        hread(line_i, hex_in);
        int_i(idx) := conv_integer(IEEE.std_logic_arith.unsigned(hex_in));
        idx := idx + 1;
      end loop;
      img_proc_flag <= '1';
      padding_flag <= '1';
    else
      img_proc_flag <= '1';
    end if;
    
    if(padding_flag = '1') then
      for y in padding_size to (padding_dim - padding_size)-1 loop
        for x in padding_size to (padding_dim - padding_size)-1 loop
          padded_img(y,x) := int_i((y-padding_size)*img_dim + (x-padding_size));
        end loop;
      end loop;
      padding_flag <= '0';
    else
      
   	end if;
   	if(img_proc_flag = '1' and padding_flag = '0') then
   	  img_proc_flag <= '1';
   	  padding_flag <= '0';
   	  --if(ready = '0') then
	    en <= '1';
	    sig_padded_img <= padded_img;
 	    --end if;
 	    
 	    --for i in 0 to kernel_dim - 1 loop
 	      --for j in 0 to kernel_dim -1 loop
 	          --image_slice(i,j) <= padded_img(id_y+i,id_x+j);
 	       --end loop;
 	    --end loop;
 	    
 	    
 	   -- if(id_y = img_dim - 1 and id_x = img_dim - 1) then
 	  --    done <= '1';
 	   -- elsif(id_x = img_dim - 1) then
 	    --  id_y <= id_y + 1;
 	   --   id_x <= 0;
 	  --  else
 	   --   id_x <= id_x + 1;
 	  --  end if;
 	    
 	  end if;
 	  
 	  
-- 	  if(ready = '1' and done = '0') then
-- 	    en <= '0';
-- 	    for oi in 0 to (img_dim * img_dim)-1 loop
-- 	      hex_out := std_logic_vector(to_signed(output(oi), 16));
-- 	      hwrite(out_row, hex_out);
-- 	      writeline(output_image_file, out_row);
-- 	    end loop;
-- 	    done <= '1';
-- 	  end if;
  end process;
  
  
  --process(new_conv_out, done, ready) 
  process(clk)
      variable out_row: line;
  begin
    if(rising_edge(clk)) then
    if(en = '1') then
 	    if(done = '0') then
 	      for i in 0 to kernel_dim - 1 loop
 	        for j in 0 to kernel_dim -1 loop
 	          image_slice(i,j) <= sig_padded_img(id_y+i,id_x+j);
 	        end loop;
 	      end loop;
 	      new_hex_out <= std_logic_vector(to_signed(new_conv_out, 16));
 	      hwrite(out_row, new_hex_out);
 	      writeline(output_image_file, out_row);
 	      if(id_y = img_dim and id_x = img_dim - 1) then
 	        done <= '1';
 	      elsif(id_x = img_dim - 1) then
 	        id_y <= id_y + 1;
 	        id_x <= 0;
 	      else
 	        id_x <= id_x + 1;
 	    end if;
 	    end if;
 	  end if;
 	  end if;
  end process;
  clk <= not clk after 5 ns;
  --gauss_en <= ready1 and ready2;
  
end behave;