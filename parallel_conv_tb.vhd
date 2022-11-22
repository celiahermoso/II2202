library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use ieee.numeric_std.all;
USE std.textio.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;

use work.convolution_pkg.ALL;


architecture parallel of test is
  
  component vec_convolution is
    generic (--padding_d  :integer  := padding_dim;
	           --img_d :integer  := img_dim;
             k_d  :integer  := kernel_dim);
    port (clk, en: IN std_logic;
          img_in_1: IN integer_vector (0 to k_d-1); -- input image array
          img_in_2: IN integer_vector (0 to k_d-1);
          img_in_3: IN integer_vector (0 to k_d-1);
          kernel_in: IN integer_vector (0 to (k_d*k_d)-1); -- input kernel array
          ready: OUT std_logic;
          --new_img: OUT integer_vector (0 to (img_d)*(img_d)-1)); -- output image
          new_img: OUT integer);
  end component;
  
  signal clk: std_logic := '0';
  signal output: integer_vector (0 to (img_dim)*(img_dim)-1) := (others => 0);
  --Input Kernel for Laplacian filter
  signal input_kernel: integer_vector (0 to (kernel_dim*kernel_dim)-1) := (0, 1, 0, 1, -4, 1, 0, 1, 0); 
  --Padded image size declaration (two rows and two column of zeros added on the edges of the image) SIGNAL
  signal sig_padded_img: integer_vector(0 to (padding_dim*padding_dim)-1) := (others => 0);
  --Files that are going to be read from and written to. Path is declared in conv_package.vhd
  file input_image_file : text open read_mode is input_file_path;
  file output_image_file : text open write_mode is output_file_path;
  
  type integer_array is array (integer range <>) of integer; --This is already declared in conv_package but needed here for the process
  --Flags for the process
  signal img_proc_flag, padding_flag: std_logic := '0';
  signal en,ready,done: std_logic := '0';
  
  --Chunk of the image that is going to be parallelized
  signal image_slice: img_type(0 to kernel_dim-1, 0 to kernel_dim -1) := (others => (others => 0));
  --Vector containing the pixels of the processed image
  signal new_conv_out_vector: integer_vector(0 to (img_dim*img_dim)-1) := (others => 0);
  --
  signal ready_vector: std_logic_vector(0 to (img_dim*img_dim)-1):= (others => '0');
  
 -- signal id_x, id_y: integer := 0;
  
begin
  
  
  CONV_G: for i in 0 to (img_dim*img_dim)-1 generate
    begin
        conv: vec_convolution
        port map(
          en => en,
          ready => ready_vector(i),
          clk => clk,
          --new_img => output,
          new_img => new_conv_out_vector(i),
          img_in_1 => sig_padded_img(i to i + kernel_dim-1),
          img_in_2 => sig_padded_img(i + padding_dim to i + padding_dim + kernel_dim-1),
          img_in_3 => sig_padded_img(i + 2*padding_dim to i + 2*padding_dim + kernel_dim-1),
          kernel_in => input_kernel
        );
    end generate;
  
process(img_proc_flag, padding_flag, ready, done)
    --To read and write lines in the input/output files 
    variable line_i: line;
    variable out_row: line;
    --Index to fo through the file that is being read
    variable idx: integer := 0;
    --Input vector read from file with the hexadecimal values of the pixels of preprocessed image
    variable hex_in: std_logic_vector(7 downto 0) := (others => '0');
    --Output vector containing pixels values in hexadecimal
    variable hex_out: std_logic_vector(15 downto 0) := (others => '0');
    --Padded image size declaration (two rows and two column of zeros added on the edges of the image) VARIABLE
    variable padded_img: img_type (0 to padding_dim-1, 0 to padding_dim-1) := (others => (others => 0));
    --Integers decimal values of the pixels of the image that is going to be processed
    variable int_i: integer_array(0 to (img_dim*img_dim));
    
    --variable int_i: integer_array(0 to (128*128));  
    --variable vec_idx: integer := 0;
    
  begin
    --Read pixels values from file
    if(img_proc_flag = '0') then
      while not endfile(input_image_file) loop
        readline(input_image_file, line_i);
        hread(line_i, hex_in);
        int_i(idx) := conv_integer(IEEE.std_logic_arith.unsigned(hex_in));
        idx := idx + 1;
      end loop;
      img_proc_flag <= '1'; --Copying pixels values from file is done
      padding_flag <= '1';  --Ready to add the padding to the image
    else
      img_proc_flag <= '1'; 
    end if;
    
    --Padding of the image (add two rows and two columns of zeros to the edges of the preprocessed input image)
    if(padding_flag = '1') then
      for y in padding_size to (padding_dim - padding_size)-1 loop
        for x in padding_size to (padding_dim - padding_size)-1 loop
          padded_img(y,x) := int_i((y-padding_size)*img_dim + (x-padding_size)); 
        end loop;
      end loop;
      padding_flag <= '0'; --It is not allowed to do the padding as it has already been done 
    else
   	end if;
   	
   	--Once the pixels have been read from file (img_proc_flag = '1') and padding is done (padding_flag = '0')
   	if(img_proc_flag = '1' and padding_flag = '0') then
   	  img_proc_flag <= '1';
   	  padding_flag <= '0';
	    --Assignment from VARIABLE padded_img 2D array to SIGNAL INTEGER_VECTOR sig_padded_img
	    for y in 0 to padding_dim-1 loop
        for x in 0 to padding_dim-1 loop
          sig_padded_img(y*padding_dim + x) <= padded_img(y,x); --From 2D to 1D
        end loop;
      end loop;
      en <= '1';
      --ready <= '1';
 	  end if;
 	  
 	  --Write output pixels of the processed image to a file in hexadecimal format
 	  if(ready = '1' and done = '0') then
 	    en <= '0';
 	    for oi in 0 to (img_dim * img_dim)-1 loop
 	       hex_out := std_logic_vector(to_signed(new_conv_out_vector(oi),16));
 	       --hex_out := conv_signed(new_conv_out_vector(oi),32);
 	       hwrite(out_row, hex_out);
 	       writeline(output_image_file, out_row);
 	     end loop;
 	     done <= '1';
 	  end if;
 	  
  end process;
  
  clk <= not clk after 5 ns;
  
end parallel;