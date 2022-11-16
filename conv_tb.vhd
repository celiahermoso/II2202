library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;
USE std.textio.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;

use work.Convolution_pkg.ALL;

entity test is
  constant img_dim: integer := 128; -- dimensions of input image, assuming square shape
  constant kernel_dim: integer := 3; -- dimensions of kernel, assuming square shape
  --constant output_dim: integer := (2**((img_dim - kernel_dim) + 1))-1;
  constant padding_dim: integer := img_dim + 2;
  constant input_file_path: string := "D:\0-EIT\KTH\P1\RM\implementation\repo\ImageRawArrayHex.txt";
  constant output_file_path: string := "D:\0-EIT\KTH\P1\RM\implementation\repo\outArrayHex.txt";
end entity;


architecture behave of test is
  component convolution is
    generic (padding_d  :integer  := padding_dim;
	           img_d :integer  := img_dim;
             k_width  :integer  := kernel_dim;
             k_height :integer  := kernel_dim);
    port (clk, en: IN std_logic;
          img_in: IN img_type (0 to padding_dim-1, 0 to padding_dim-1);
          kernel_in: IN kernel_type (0 to k_width-1, 0 to k_width-1);
          ready: OUT std_logic;
          new_img: OUT integer_vector (0 to (img_d)*(img_d)-1));
  end component;
  
  signal clk: std_logic := '0';
  signal output: integer_vector (0 to (img_dim)*(img_dim)-1) := (others => 0);
  --signal input_img: img_type (0 to img_dim-1, 0 to img_dim-1) := (
  --        (2, 2, 1, 1, 1, 1),
  --        (1, 1, 1, 1, 1, 2),
  --        (2, 2, 1, 1, 1, 1),
  --  	     (1, 1, 1, 1, 1, 2),
  --        (3, 3, 1, 1, 1, 1),
  --        (1, 1, 2, 2, 2, 2));
  signal input_kernel: kernel_type (0 to kernel_dim-1, 0 to kernel_dim-1) := (
            (0, 1, 0),
           (1, -4, 1),
            (0, 1, 0));
  
  signal padded_img: img_type (0 to padding_dim-1, 0 to padding_dim-1) := (others => (others => 0));
  file input_image_file : text open read_mode is input_file_path;
  file output_image_file : text open write_mode is output_file_path;
  type integer_array is array (integer range <>) of integer;
  signal img_proc_flag, padding_flag: std_logic := '0';
  signal int_i: integer_array(0 to (img_dim*img_dim));
  signal en,ready,done: std_logic := '0';
begin
  conv: convolution
        port map(
          en => en,
          ready => ready,
          clk => clk,
          new_img => output,
          img_in => padded_img,
          kernel_in => input_kernel
        );
        
  process(img_proc_flag, padding_flag, ready, done)
    variable line_i: line;
    variable hex_in: std_logic_vector(7 downto 0) := (others => '0');
    variable hex_out: std_logic_vector(15 downto 0) := (others => '0');
    --variable int_i: integer_array(0 to (128*128));  
    variable idx: integer := 0;
    variable out_row: line;
  begin
    if(img_proc_flag = '0') then
      while not endfile(input_image_file) loop
        readline(input_image_file, line_i);
        hread(line_i, hex_in);
        int_i(idx) <= conv_integer(IEEE.std_logic_arith.unsigned(hex_in));
        idx := idx + 1;
      end loop;
      img_proc_flag <= '1';
      padding_flag <= '1';
    else
      img_proc_flag <= '1';
    end if;
    
    if(padding_flag = '1') then
      for y in 1 to (padding_dim - 2) loop
        for x in 1 to (padding_dim - 2) loop
          padded_img(y,x) <= int_i((y-1)*img_dim + (x-1));
        end loop;
      end loop;
      padding_flag <= '0';
    else
      
   	end if;
   	if(img_proc_flag = '1' and padding_flag = '0') then
   	  img_proc_flag <= '1';
   	  padding_flag <= '0';
   	  if(ready = '0') then
   	       en <= '1';
 	    end if;
 	  end if;
 	  
 	  if(ready = '1' and done = '0') then
 	    en <= '0';
 	    for oi in 0 to (img_dim * img_dim)-1 loop
 	      hex_out := std_logic_vector(to_signed(output(oi), 16));
 	      hwrite(out_row, hex_out);
 	      writeline(output_image_file, out_row);
 	    end loop;
 	    done <= '1';
 	  end if;
  end process;
  clk <= not clk after 5 ns;
  
  
  
end behave;