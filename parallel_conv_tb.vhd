library ieee;
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
  
  signal input_kernel: integer_vector (0 to (kernel_dim*kernel_dim)-1) := (0, 1, 0, 1, -4, 1, 0, 1, 0);
  
  signal sig_padded_img: integer_vector(0 to (padding_dim*padding_dim)-1) := (others => 0);
  
  file input_image_file : text open read_mode is input_file_path;
  file output_image_file : text open write_mode is output_file_path;
  type integer_array is array (integer range <>) of integer;
  signal img_proc_flag, padding_flag: std_logic := '0';
  signal en,ready,done: std_logic := '0';
  
  
  signal new_conv_out_vector: integer_vector(0 to (img_dim*img_dim)-1) := (others => 0);
  signal image_slice: img_type(0 to kernel_dim-1, 0 to kernel_dim -1) := (others => (others => 0));
  
  signal id_x, id_y: integer := 0;
  signal new_hex_out: std_logic_vector(15 downto 0) := (others => '0');
  
  signal ready_vector: std_logic_vector(0 to (img_dim*img_dim)-1):= (others => '0');
  
  
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
    variable line_i: line;
    variable hex_in: std_logic_vector(7 downto 0) := (others => '0');
    variable hex_out: std_logic_vector(15 downto 0) := (others => '0');
    --variable int_i: integer_array(0 to (128*128));  
    variable idx: integer := 0;
    
    variable vec_idx: integer := 0;
        
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
	    
	    
	    for y in 0 to padding_dim-1 loop
        for x in 0 to padding_dim-1 loop
          sig_padded_img(y*padding_dim + x) <= padded_img(y,x);
        end loop;
      end loop;
      en <= '1';
 	    
 	  end if;
 	  
 	  

  end process;
  
  clk <= not clk after 5 ns;
  
end parallel;