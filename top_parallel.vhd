library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.convolution_pkg.ALL;
use work.all;

use IEEE.std_logic_arith.all;

entity top_parallel is
  generic(padding_d  :integer := padding_dim;
	           img_d :integer := img_dim;
             k_d  :integer := kernel_dim);
             
             
--if we want to test in the testbench, we need an input en signal
  port (clk, reset: IN std_logic;
          --en: IN std_logic;
          --img_in: IN img_type (0 to padding_d-1, 0 to padding_d-1); -- input image array
          --kernel_in: IN kernel_type (0 to k_d-1, 0 to k_d-1); -- input kernel array
          ready: OUT std_logic);
          --img_out: OUT integer_vector (0 to (img_d)*(img_d)-1));
end top_parallel;


architecture behave of top_parallel is
  type states is (reading, processing, writing, done);
	  
	component input_ram is
	 port(
		address		: IN STD_LOGIC_VECTOR (14 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rden		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
	end component;
	 
	component out_ram is
	 port(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
	end component;
	
	 component vec_convolution is
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
  end component;
  
  signal en: std_logic := '0';
  --Laplacian kernel
  signal input_kernel: integer_vector (0 to (kernel_dim*kernel_dim)-1) := (0, 1, 0, 1, -4, 1, 0, 1, 0); 
  --HUGE array where the input image from fake memory is going to be loaded
  signal array_input_image: integer_vector (0 to padding_dim*padding_dim-1) := (others => 1);
  --Slices of the image that are input to the vec_convolution
  --signal image_slice_1: integer_vector (0 to k_d-1) := (others => 0);
  --signal image_slice_2: integer_vector (0 to k_d-1) := (others => 0);
  --signal image_slice_3: integer_vector (0 to k_d-1) := (others => 0);
  
  --Vector containing the pixels of the processed image
  signal new_conv_out_vector: integer_vector(0 to (img_dim*img_dim)-1) := (others => 0);
  
  signal input_image_read: std_logic_vector(15 downto 0);
  signal input_image_write: std_logic_vector(15 downto 0);
  
  signal output_image_read: std_logic_vector(15 downto 0);
  signal output_image_write: std_logic_vector(15 downto 0);
  
  signal input_image_address: std_logic_vector(14 downto 0);
  signal output_image_address: std_logic_vector(13 downto 0);
  
  signal iwren, irden, owren: std_logic := '0';
  
  signal conv_ready: std_logic_vector(0 to (img_dim*img_dim)-1):= (others => '0');
  
  signal ready_sig: std_logic := '0';
  
  signal input_idx: integer:=0;
  signal address_idx: integer:=0;
  signal output_idx: integer := 0;
  
  

begin

    --inram: entity work.input_ram(syn)
	  inram: entity work.input_ram(fake_memory)
		port map(
			clock => clk,
			address => input_image_address,
			wren => iwren,
			rden => irden,
			data => input_image_write,
			q => input_image_read
		);
		
	 --outram: entity work.out_ram(syn)
	  outram: entity work.out_ram(fake_memory)
		port map(
			clock => clk,
			address => output_image_address,
			wren => owren,
			data => output_image_write,
			q => output_image_read
		);
  
  
  --Generate block like in the convolution_vectors testbench
   CONV_G1: for j in 0 to img_dim-1 generate
    CONV_G2:  for i in 0 to img_dim-1 generate
                --i_padded := i;
                begin
                conv: vec_convolution
                generic map(
                  k_d => kernel_dim
                )
                port map(
                  en => en,
                  ready => conv_ready(j*img_dim + i),
                  clk => clk,
                  new_img => new_conv_out_vector(j*img_dim + i),
                  img_in_1 => array_input_image(j*padding_dim + i + 0*padding_dim to j*padding_dim + i + 0*padding_dim + k_d-1),
                  img_in_2 => array_input_image(j*padding_dim + i + 1*padding_dim to j*padding_dim + i + 1*padding_dim + k_d-1),
                  img_in_3 => array_input_image(j*padding_dim + i + 2*padding_dim to j*padding_dim + i + 2*padding_dim + k_d-1),
                  kernel_in => input_kernel
                  );
              end generate;
            end generate;
		  
	ready <= ready_sig;
	
	process(reset,clk)
	  --check when it updates
	  --variable input_idx: integer:=0;
	
	  begin
	  if(reset = '1') then
			en <= '0';
			iwren <= '0';
			irden <= '1';
			owren <= '0';
			ready_sig <= '0';
	    input_image_write <= (others => '0');
			input_image_address <= (others => '0');
			output_image_read <= (others => '0');
			output_image_write <= (others => '0');
			output_image_address <= (others => '0');
			array_input_image <= (others => 1);
		elsif(rising_edge(clk)) then
		  --Copyimg from the RAM into a huge array
	    --No for loops in the input RAM
	    --signals get assigned when you exit the process
	    if(address_idx < padding_dim*padding_dim) then
		    input_image_address <= std_logic_vector(to_unsigned(input_idx, 15)); 
		    --sig_padded_image is input_image_read because it is done in the preprocessing in MATLAB
		    array_input_image(address_idx) <= conv_integer(IEEE.std_logic_arith.unsigned(input_image_read));
		  else 
		    address_idx <= address_idx;
		  end if;
		   
		  if(ready_sig = '1') then
			 output_image_address <= std_logic_vector(to_unsigned(output_idx, 14));
			 output_image_write <= std_logic_vector(to_signed(new_conv_out_vector(output_idx), 16));
--		 owren <= '0';
--		  elsif(conv_ready = (conv_ready'range => '1')) then  
		  else
			 output_imag+e_address <= output_image_address;
			 output_image_write <= output_image_write;
			 --owren <= '1';
		  end if;
		  
		  if(input_idx < 2) then
		    address_idx <= address_idx;
		  else 
		    address_idx <= address_idx+1;
		  end if;
		  
		  if(input_idx = 130) then
		  input_idx <= input_idx;
		  end if;
		  
		  --Input image from fake input ram is fully loaded
		  if(input_idx = padding_dim*padding_dim-1) then
		    ready_sig <= '1';
		    owren <= '1';
		    if (output_idx < img_dim*img_dim-1) then
		      output_idx <= output_idx + 1;
		    else 
		      owren <= '0';
		    end if;
		   -- output_idx <= output_idx + 1;
		  else
		    input_idx <= input_idx+1;
		    ready_sig <= '0';
		  end if;				  
	 end if;
	end process; 

  
end behave;


