library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;  

entity orion2010 is
port(
CLK50 		:	in std_logic;
VGA_R 		: 	out std_logic_vector(2 downto 0);
VGA_G 		: 	out std_logic_vector(2 downto 0);
VGA_B 		: 	out std_logic_vector(2 downto 0);
VGA_HS		: 	out std_logic;
VGA_VS 		: 	out std_logic;
SOUND_L 		:	out std_logic;
SOUND_R 		: 	out std_logic;
SRAM_ADDR 	: 	out std_logic_vector(20 downto 0);
SRAM_DQ		: 	inout std_logic_vector(7 downto 0);
SRAM_WE_N	: 	out std_logic;
SRAM_CE_N	: 	out std_logic;
STD_N 		: 	out std_logic;
STD_B_N		:	out std_logic;
PS2_CLK 		: 	in std_logic;
PS2_DAT		:	in std_logic;
SD_DAT3		:	out std_logic; -- CS_N
SD_DAT 		: 	in std_logic; -- MISO
SD_CMD 		: out std_logic; -- MOSI
SD_CLK 		: out std_logic -- SCK
); 
end orion2010;  

architecture orion2010_arch of orion2010 is

signal clk20 : std_logic;
signal clk : std_logic;
signal r: std_logic;
signal g: std_logic;
signal b: std_logic;
signal i: std_logic;
signal sound: std_logic;
signal wr : std_logic;
signal rd : std_logic;
signal mreq : std_logic;
signal m1 : std_logic;
signal iorq : std_logic;
signal csf7_n : std_logic;
signal wait_n : std_logic;
signal ram_oe0 : std_logic;
signal ram_we0 : std_logic;
signal rom_oe : std_logic;
signal rxd : std_logic;
signal txd : std_logic;
signal rom_we : std_logic;
signal dac_out : std_logic;
signal d : std_logic_vector(7 downto 0);

COMPONENT vga_test IS
PORT (
	clock:           in std_logic;
	h_sync:          out std_logic;  
	v_sync:          out std_logic;
	red:             out std_logic;
	green:           out std_logic;
	blue:            out std_logic;
	bright:          out std_logic;
	sound:           out std_logic;
	a:               out std_logic_vector(16 downto 0);
	a17,a18:         out std_logic;
	d:               inout std_logic_vector(7 downto 0);
	wr,rd,mreq:      out std_logic;
	m1,iorq,csf7_n:  out std_logic;
	wait_n:          in std_logic;
	ram_oe0,ram_we0: out std_logic;
	rom_oe:          out std_logic;
	ps2_clk:         in std_logic;
	ps2_data:        in std_logic;
	mosi,sck:        out std_logic;
	miso:            in std_logic;
	cs_sd:           out std_logic;
	rxd:             in std_logic;
	txd:             out std_logic;
	rom_we:          out std_logic;
	dac_out:         out std_logic
);
END COMPONENT;

COMPONENT clock IS
PORT (
	CLK_IN1:           in std_logic;
	CLK_OUT1: 			  out std_logic
);
END COMPONENT;

begin

VGA_R <= "110" when i='1' and r='1' else "010" when r='1' else "000";
VGA_G <= "110" when i='1' and g='1' else "010" when g='1' else "000";
VGA_B <= "110" when i='1' and b='1' else "010" when b='1' else "000";
SOUND_L <= dac_out;
SOUND_R <= dac_out;
SRAM_ADDR(20 downto 18) <= (others => '0');
SRAM_WE_N <= ram_we0;
SRAM_CE_N <= '0';
STD_N <= '0';
STD_B_N <= '1';
SRAM_DQ <= d(7 downto 0) when ram_we0 = '0' else "ZZZZZZZZ";
d <= SRAM_DQ when ram_oe0 = '0' else "ZZZZZZZZ";
wait_n <= '1';

orion:vga_test
port map (
	clock	=> clk20,
	h_sync => VGA_HS,
	v_sync => VGA_VS,
	red => r,
	green => g,
	blue => b,
	bright => i, 
	sound => sound,
	a => SRAM_ADDR(16 downto 0),
	a17 => SRAM_ADDR(17),
	a18 => open,
	d => d(7 downto 0),
	wr => wr,
	rd => rd,
	mreq => mreq,
	m1 => m1,
	iorq => iorq,
	csf7_n => csf7_n,
	wait_n => wait_n,
	ram_oe0 => ram_oe0,
	ram_we0 => ram_we0,
	rom_oe => rom_oe,
	ps2_clk => PS2_CLK,
	ps2_data => PS2_DAT,
	mosi => SD_CMD,
	sck => SD_CLK,
	miso => SD_DAT,
	cs_sd => SD_DAT3,
	rxd => rxd,
	txd => txd,
	rom_we => rom_we,
	dac_out => dac_out
);

clocks:clock
port map (
	CLK_IN1 => CLK50,
	CLK_OUT1 => clk20
);

end orion2010_arch;