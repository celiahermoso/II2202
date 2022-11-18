library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.convolution_pkg.ALL;

use IEEE.std_logic_arith.all;

entity top is
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
end top;


architecture behave of top is

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


    component convolution is
    generic (padding_d  :integer;
	           img_d :integer;
             k_d  :integer);
    port (clk, en: IN std_logic;
          img_in: IN img_type (0 to padding_d-1, 0 to padding_d-1);
          kernel_in: IN kernel_type (0 to k_d-1, 0 to k_d-1);
          ready: OUT std_logic;
          new_img: OUT integer_vector (0 to (img_d)*(img_d)-1));
  end component;
  
  signal en: std_logic := '0';
  signal img_ready:std_logic := '0';
  
  signal input_image: img_type (0 to padding_d-1, 0 to padding_d-1) := (others => (others => 0));
  signal kernel_in: kernel_type (0 to k_d-1, 0 to k_d-1) := dog_kernel_1;
  signal output_image: integer_vector (0 to (img_d)*(img_d)-1) := (others => 0);
  
  signal input_image_read: std_logic_vector(15 downto 0);
  signal input_image_write: std_logic_vector(15 downto 0);
  
  signal output_image_read: std_logic_vector(15 downto 0);
  signal output_image_write: std_logic_vector(15 downto 0);
  
  signal input_image_address: std_logic_vector(14 downto 0);
  signal output_image_address: std_logic_vector(13 downto 0);
  
  signal iwren, irden, owren: std_logic := '0';
  
  signal top_state, next_state: std_logic_vector(1 downto 0) := "00";
  
  begin
  
	 inram: input_ram
		port map(
			clock => clk,
			address => input_image_address,
			wren => iwren,
			rden => irden,
			data => input_image_write,
			q => input_image_read
		);
		
	 outram: out_ram
		port map(
			clock => clk,
			address => output_image_address,
			wren => owren,
			data => output_image_write,
			q => output_image_read
		);
  
  
    conv: convolution
        generic map(
          padding_d => padding_d,
          img_d => img_d,
          k_d => k_d
        )
        port map(
          en => en,
          ready => ready,
          clk => clk,
          new_img => output_image,
          img_in => input_image,
          kernel_in => kernel_in
        );
		  
		  
	process(top_state) begin
	   case top_state is
	     when '00' =>
	       for(
	   end case;
	end process;
		  
	process(reset, clk) 
	begin
		if(reset = '1') then
		  top_state <= '00';
			en <= '0';
			input_image <= (others => (others => 0));
			iwren <= '0';
			irden <= '0';
			owren <= '0';
			input_image_read <= (others => '0');
			input_image_write <= (others => '0');
			input_image_address <= (others => '0');
			output_image_read <= (others => '0');
			output_image_write <= (others => '0');
			output_image_address <= (others => '0');
		elsif(rising_edge(clk)) then
		  irden <= '1';
			top_state <= next_state;
		end if;
	end process;
	
end behave;