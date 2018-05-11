library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;  

entity vga_test is                      -- last version for ORION-2010 rev 1.07 PCB --
port(
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
end vga_test;  

architecture vga_arch of vga_test is

component T80s is
	generic(
		Mode : integer := 1;	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write : integer := 1;	-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait : integer := 1	-- 0 => Single cycle I/O, 1 => Std I/O cycle
	);
	port(
		RESET_n		: in std_logic;
		CLK_n		: in std_logic;
		WAIT_n		: in std_logic;
		INT_n		: in std_logic;
		NMI_n		: in std_logic;
		BUSRQ_n		: in std_logic;
		M1_n		: out std_logic;
		MREQ_n		: out std_logic;
		IORQ_n		: out std_logic;
		RD_n		: out std_logic;
		WR_n		: out std_logic;
		RFSH_n		: out std_logic;
		HALT_n		: out std_logic;
		BUSAK_n		: out std_logic;
		A			: out std_logic_vector(15 downto 0);
		DI			: in std_logic_vector(7 downto 0);
		DO			: out std_logic_vector(7 downto 0)
	);
end component;

component lpm_rom1 is
	port
	(
		address		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		clken		: IN STD_LOGIC  := '1';
		clock		: IN STD_LOGIC  := '1';
		q		    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

component orionkeyboard is
 port(
   clk            :in std_logic;
   reset          :in std_logic;
   res_k          :out std_logic;
   turb_10        :out std_logic;
   turb_5         :out std_logic;
   turb_2         :out std_logic;
   rom_s          :out std_logic;
   cpm_s          :out std_logic;
   ps2_clk        :in std_logic;
   ps2_data       :in std_logic;
   rk_kb_scan     :in std_logic_vector(7 downto 0);
   rk_kb_out      :out std_logic_vector(7 downto 0);
   pref           :out std_logic_vector(1 downto 0);
   key_rus_lat    :out std_logic;
   key_us         :out std_logic;
   key_ss         :out std_logic;
   ind_rus_lat    :in std_logic;
   rk_kbo         :out std_logic_vector(7 downto 0);
   key_int        :out std_logic
);
end component;

component async_transmitter is
port( 
   clk, TxD_start     :in std_logic;
   TxD_data           :in std_logic_vector(7 downto 0);
   TxD, TxD_busy      :out std_logic  
    );
end component;

component async_receiver is
port( 
   clk, RxD           :in std_logic;
   RxD_data_ready     :out std_logic; 
   RxD_data           :out std_logic_vector(7 downto 0)  
    );
end component;

signal hcnt:     	std_logic_vector(9 downto 0)register;
signal vcnt:     	std_logic_vector(9 downto 0)register;
signal hsync:    	std_logic;
signal vsync:    	std_logic;
signal int_cnt:     std_logic_vector(18 downto 0);
signal r,g,b,i:  	std_logic;
signal blank:    	std_logic;
signal blank1:   	std_logic;
signal del:      	std_logic_vector(2 downto 0);
signal clk_cpu:  	std_logic;
signal res_n:    	std_logic;
signal res_key:  	std_logic;
signal a_buff:   	std_logic_vector(15 downto 0);
signal dataI:    	std_logic_vector(7 downto 0);
signal dataO:    	std_logic_vector(7 downto 0);
signal wr_n:     	std_logic;
signal rd_n:     	std_logic;
signal mreq_n:   	std_logic;
signal iorq_n:   	std_logic;
signal wait_cpu:    std_logic;
signal int_n:    	std_logic;
signal m1_n:        std_logic;
signal sel:      	std_logic;
signal romsel:   	std_logic;
signal portsel:  	std_logic;
signal portio:   	std_logic;
signal top:      	std_logic;
signal romd_a:   	std_logic_vector(11 downto 0);
signal romd_d:   	std_logic_vector(7 downto 0);
signal csf8,csfb:	std_logic;
signal csf9,csfa:	std_logic;
signal csfc:        std_logic;
signal f8:       	std_logic_vector(3 downto 0)register;
signal f9:       	std_logic_vector(2 downto 0)register;
signal fa:       	std_logic_vector(1 downto 0)register;
signal fe,ff:    	std_logic register;
signal fb:       	std_logic_vector(2 downto 0) register;
signal fc:       	std_logic_vector(7 downto 0) register;
signal fbint:    	std_logic register;
signal fbdis:    	std_logic register;
signal fbfull:   	std_logic register;
signal interr:   	std_logic register;
signal mode_vga: 	std_logic;
signal vid0,vid1:	std_logic_vector(7 downto 0)register;
signal vid2,vid3:	std_logic_vector(7 downto 0)register;
signal vid,vidc: 	std_logic;
signal pf400:    	std_logic_vector(7 downto 0) register;
signal pf401:    	std_logic_vector(7 downto 0) register;
signal pf402:    	std_logic_vector(7 downto 0) register;
signal csf4:     	std_logic;
signal csf5:     	std_logic;
signal pf501:    	std_logic_vector(7 downto 0) register;
signal pf502:    	std_logic_vector(7 downto 0) register;
signal p4f:         std_logic_vector(7 downto 0) register;
signal sd_mosi:  	std_logic register;
signal sd_sck:   	std_logic register;
signal sd_cs:    	std_logic register;
signal csf7:     	std_logic;
signal csf76:       std_logic;
signal csf762:   	std_logic;
signal csf763:   	std_logic;
signal csf764:   	std_logic;
signal csf765:   	std_logic;
signal csf766:   	std_logic;
signal csf767:   	std_logic;
signal csf768:   	std_logic;
signal csf769:   	std_logic;
signal csf76a:   	std_logic;
signal csfe:        std_logic;
signal pf766:       std_logic register;
signal cs:       	std_logic register;
signal mosi_buf: 	std_logic register;
signal sck_buf:  	std_logic register;
signal miso_buf: 	std_logic_vector(7 downto 0) register;
signal rom_reg:     std_logic_vector(1 downto 0) register;
signal rom_sel:     std_logic;
signal op_uart:     std_logic_vector(7 downto 0);
signal ip_uart:     std_logic_vector(7 downto 0);
signal uart_rdy:    std_logic;
signal uart_wr:     std_logic;
signal eoc,eot:     std_logic;
signal rx_reg:      std_logic_vector(7 downto 0)register;
signal rx_status:   std_logic register;
signal rx_int:      std_logic register;
signal int_buf:     std_logic register;
signal vector:      std_logic_vector(7 downto 0)register;
signal uart_speed:  std_logic_vector(1 downto 0)register;
signal uart_del:    std_logic_vector(2 downto 0)register;
signal uart_clk:    std_logic;
signal hi_rom:      std_logic;
signal cpm_rom:     std_logic register;
signal turbo_10:    std_logic;
signal turbo_5:     std_logic;
signal turbo_2:     std_logic;
signal turbo_reg:   std_logic_vector(1 downto 0)register;
signal scan_key:    std_logic_vector(7 downto 0);
signal slow:        std_logic register;
signal slow_key:    std_logic;
signal inport:      std_logic;
signal sel_1,sel_2: std_logic;
signal himem_wr:    std_logic;
signal himem_rd:    std_logic;
signal int_key:     std_logic;
signal int_keyb:    std_logic;
signal prefix:      std_logic_vector(1 downto 0);
signal dac_reg:     std_logic_vector(7 downto 0);
signal dac_cnt:     std_logic_vector(7 downto 0);
signal dac_buf:     std_logic_vector(7 downto 0);

begin

------------------------------------------Main counters------------------------------------------------
process(clock,hcnt)
begin
if (clock'event and clock='1') then
 if hcnt=575 then
  hcnt<="0000000000";
 else
  hcnt<=hcnt+1;
 end if;
end if; 
end process;

process(clock,hcnt,vcnt,interr)
begin
if (hcnt(9)'event and hcnt(9)='0') then
 if vcnt(9 downto 1)=311 then
  vcnt(9 downto 0)<="0000000000";
 else
  vcnt<=vcnt+1;
 end if;
end if;
end process; 

process(clock)
begin
if (clock'event and clock='1') then
 if int_cnt=399999 then
  int_cnt<="0000000000000000000";
 else
  int_cnt<=int_cnt+1;
 end if;
end if; 
end process;  

------------------------------------------Interrupt control-----------------------------------------------
process(clock,int_cnt,fbint)
begin
if (clock'event and clock='0') then
 if ((int_cnt=0) and fbint='1') then
  interr<='1';
 elsif int_cnt=128 then 
  interr<='0'; 
 end if;
end if;
end process;
 
int_n<='0' when ((interr='1') or (int_buf='1') or (int_keyb='1')) else '1';

process(eoc,iorq_n,m1_n,rx_int)
begin
 if ((eoc'event and eoc='1') and rx_int='1') then
  int_buf<='1';
 end if;
 if (iorq_n='0' and m1_n='0') then
  int_buf<='0';
 end if;
end process;   

process(int_key,iorq_n,m1_n,pf766)
begin
 if ((int_key'event and int_key='1') and pf766='1') then
  int_keyb<='1';
 end if;
 if (iorq_n='0' and m1_n='0') then
  int_keyb<='0';
 end if;
end process;

process(clock,eoc,interr,int_buf,int_keyb)           
begin
if (clock'event and clock='1') then
 if eoc='1' then 
  vector<="11111101";
 elsif (int_keyb='1' and int_buf='0') then
  vector<="11111011"; 
 elsif (interr='1' and int_buf='0' and int_keyb='0') then 
  vector<="11111111";
 end if;
end if; 
end process;

-----------------------------------------Main Z-80 clock generator-------------------------------------
process(clock)
begin
 if (clock'event and clock='1') then
  del<=del+1;
 end if;
end process;

process(clock,turbo_2,turbo_5,turbo_10,csf767,wr_n,dataO)
begin
if (clock'event and clock='1') then
 if (turbo_5='1') then turbo_reg<="00"; end if;
 if (turbo_10='1') then turbo_reg<="01"; end if;
 if (turbo_2='1') then turbo_reg<="10"; end if;
 if (csf767='0' and wr_n='0') then turbo_reg<=dataO(6 downto 5); end if;
end if;  
end process;

process(clock,hcnt,clk_cpu,turbo_reg,del,sel,csf5,a_buff)  
begin
 if (clock'event and clock='1') then
  if (turbo_reg="10") then  
    clk_cpu<=del(2);  
  elsif (turbo_reg="00") then
   if hcnt(1)='1' then 
    clk_cpu<=del(0);
   end if;   
  else
   if turbo_reg="01" then 
    if sel='0' then
     clk_cpu<=del(0);  
    end if;
   end if; 
  end if;
 end if;
end process;

-------------------------------------DAC-------------------------------------
dac_reg<=dataO when (csf76a='0' and (wr_n'event and wr_n='1'));
   
process(clock,dac_buf,dac_reg,dac_cnt)
begin
if ((clock'event and clock='1')) then
 if (dac_cnt>0) then
  dac_cnt<=dac_cnt-1;
  if dac_buf>0 then 
   dac_buf<=dac_buf-1;
   dac_out<='1'; 
  else
   dac_out<='0'; 
  end if;
 else
  dac_cnt<="11111111";
  dac_buf<=dac_reg; 
 end if;
end if;
end process;

-------------------------------------------Control & select signals-----------------------------------------------
res_n<='0' when (hi_rom='1' or res_key='1') else '1';
himem_wr<='1' when ((romsel='0') or (p4f(2)='0' and romsel='1')) and mreq_n='0' else '0';
himem_rd<='1' when (mreq_n='0' and csf5='1' and csf7='1' and (portsel='0' or (portsel='1' and fbfull='1'))) else '0';
ram_oe0<='0' when ((rd_n='0' and himem_rd='1') or sel='1') else '1';
romd_a<=cpm_rom & a_buff(10 downto 0);
ram_we0<='0' when (wr_n='0' and sel='0' and clock='0' and himem_wr='1') else '1';
rom_oe<='0' when (sel='0' and mreq_n='0' and rd_n='0' and csf5='0' and fbfull='0' and p4f(1)='0') else '1';
cpm_rom<= not(cpm_rom) when (hi_rom'event and hi_rom='1');  
top<='1' when (a_buff(15 downto 12)="1111") else '0';
romsel<='1' when (a_buff(15 downto 11)="11111") else '0';
portsel<='1' when (a_buff(15 downto 10)="111101") else '0';
portio<='1' when (iorq_n='0') else '0';
csfe<='1' when (a_buff(7 downto 0)="11111110") else '0';
rd<='0' when (rd_n='0' and iorq_n='0' and inport='0' and csfe='0' and sel='0') else '1';
wr<='0' when (wr_n='0' and iorq_n='0' and inport='0' and sel='0') else '1';
mreq<='0' when mreq_n='0' else '1';
iorq<='0' when iorq_n='0' else '1';
m1<='0' when m1_n='0' else '1';
wait_cpu<='0' when wait_n='0' else '1';
csf7_n<='0' when csf76='0' else '1';

process(f8,hcnt)
begin
 if f8(2 downto 1)="01" then
  sel<='0';
 elsif (hcnt(2 downto 0)="000") then     
  sel<='1';
 else
  sel<='0';
 end if;
end process;  

process(csf767,wr_n,dataO,rom_sel,rom_reg)
begin
 if (csf767='0' and wr_n='0') then
  rom_reg<=dataO(4 downto 3);
 elsif (rom_sel'event and rom_sel='1') then
  rom_reg<=rom_reg+1;
 end if;
end process;   

-------------------------------------Ports selectors & registers section------------------------------------------
pf400<=dataO when ((wr_n'event and wr_n='1') and csf4='0' and a_buff(3 downto 0)="0000");
pf501<=dataO when ((wr_n'event and wr_n='1') and csf5='0' and a_buff(3 downto 0)="0001");
pf502<=dataO when ((wr_n'event and wr_n='1') and csf5='0' and a_buff(3 downto 0)="0010");

process(res_n,dataO,csf766,wr_n)
begin
if res_n='0' then
 pf766<='0';
elsif ((wr_n'event and wr_n='1') and csf766='0') then
 pf766<=dataO(6);
end if;
end process;  

process(a_buff,portsel,portio,fbfull,p4f)
begin
 if (portsel='1' and p4f(0)='0') then
  case portsel & fbfull & a_buff(9 downto 4) is
   when "10000000" =>csf4<='0';
                     csf5<='1';
                     csf7<='1';
   when "10010000" =>csf4<='1';
                     csf5<='0';
                     csf7<='1'; 
   when "10110110" =>csf4<='1';
                     csf5<='1';
                     csf7<='0';                                     
   when others     =>csf4<='1'; 
                     csf5<='1';
                     csf7<='1';          
  end case;
 else
 if portio='1' then
  case a_buff(7 downto 4) is
   when"0001" =>csf4<='0';
                 csf5<='1';
                 csf7<='1';
                 inport<='1';
   when"0010" =>csf4<='1';
                 csf5<='0';
                 csf7<='1';
                 inport<='1';
   when"0100" =>csf4<='1';
                 csf5<='1';
                 csf7<='0'; 
                 inport<='1';                               
   when others =>csf4<='1';
                 csf5<='1';
                 csf7<='1';
                 inport<='0';
  end case;
 else
                 csf4<='1';
                 csf5<='1';
                 csf7<='1';
                 inport<='0';
 end if; 
 end if;                                
end process;

--------------------------------System ports----------------------------------------- 
csf8<='1' when (a_buff(15 downto 8)="11111000" and mreq_n='0' and fbfull='0' and p4f(0)='0') or 
 (a_buff(7 downto 0)="11111000" and iorq_n='0') else '0';
csf9<='1' when (a_buff(15 downto 8)="11111001" and mreq_n='0' and fbfull='0' and p4f(0)='0') or 
 (a_buff(7 downto 0)="11111001" and iorq_n='0') else '0';
csfa<='1' when (a_buff(15 downto 8)="11111010" and mreq_n='0' and fbfull='0' and p4f(0)='0') or 
 (a_buff(7 downto 0)="11111010" and iorq_n='0') else '0';
csfb<='1' when (a_buff(15 downto 8)="11111011" and mreq_n='0' and fbfull='0' and p4f(0)='0') or 
 (a_buff(7 downto 0)="11111011" and iorq_n='0') else '0';
csfc<='1' when (a_buff(15 downto 8)="11111100" and mreq_n='0' and fbfull='0' and p4f(0)='0') or 
 (a_buff(7 downto 0)="11111100" and iorq_n='0') else '0'; 

p4f<=dataO(7 downto 0) when (csf767='0' and iorq_n='0' and (wr_n'event and wr_n='1'));
rom_we<='0' when (p4f(7)='1' and csf5='0' and a_buff(3 downto 0)="0000" and wr_n='0') else '1'; 

process(res_n,wr_n,dataO,csf8) -- F800 --
begin
 if res_n='0' then
   f8<="0000";
 elsif csf8='1' and (wr_n'event and wr_n='1') then
   f8<=dataO(3 downto 0);
end if;
end process; 
 
process(res_n,wr_n,dataO,csf9) -- F900 --
begin
 if res_n='0' then
   f9<="000";
 elsif csf9='1' and (wr_n'event and wr_n='1') then
   f9<=dataO(2 downto 0);
end if;
end process;

process(res_n,wr_n,dataO,csfa) -- FA00 --
begin
 if res_n='0' then
   fa<="00";
   mode_vga<='0';
 elsif csfa='1' and (wr_n'event and wr_n='1') then
   fa<=dataO(1 downto 0);
   mode_vga<=dataO(7);
 end if;
end process;

process(res_n,wr_n,dataO,csfb) -- FB00 --
begin
 if res_n='0' then
   fb<="000";
   fbfull<='0';
   fbint<='0';
   fbdis<='1';
 elsif csfb='1' and (wr_n'event and wr_n='1') then
   fb<=dataO(2 downto 0);
   fbfull<=dataO(5);
   fbint<=dataO(6);
   fbdis<=dataO(7);
 end if;
end process;

process(res_n,wr_n,dataO,csfc) -- FC00 --
begin
 if res_n='0' then
   fc<="00000000";
 elsif csfc='1' and (wr_n'event and wr_n='1') then
   fc<=dataO(7 downto 0);
end if;
end process;

------------------------------------Sound (FE & FF ports)------------------------------
process(a_buff,iorq_n,wr_n,dataO,csfe)
begin
if (iorq_n='0' and (wr_n'event and wr_n='1')) then
 if (csfe='1') then
  fe<=dataO(4);
 end if;
 if (a_buff(7 downto 0)="11111111") then
  ff<=not ff;
 end if;
end if;   
end process;

sound<= fe xor ff;

------------------------------------Main extensions ports F76x---------------------------
csf76<='0' when (csf7='0' and a_buff(3 downto 1)="000") else '1';
csf762<='0' when (csf7='0' and a_buff(3 downto 0)="0010") else '1';
csf763<='0' when (csf7='0' and a_buff(3 downto 0)="0011") else '1';
csf764<='0' when (csf7='0' and a_buff(3 downto 0)="0100") else '1';
csf765<='0' when (csf7='0' and a_buff(3 downto 0)="0101") else '1';
csf766<='0' when (csf7='0' and a_buff(3 downto 0)="0110") else '1';
csf767<='0' when (csf7='0' and a_buff(3 downto 0)="0111") else '1';
csf768<='0' when (csf7='0' and a_buff(3 downto 0)="1000") else '1';
csf769<='0' when (csf7='0' and a_buff(3 downto 0)="1001") else '1';
csf76a<='0' when (csf7='0' and a_buff(3 downto 0)="1010") else '1';

----------------------------------------SD-interface--------------------------------------
cs<=dataO(2) when (csf762='0' and (wr_n'event and wr_n='1'));
cs_sd<='1' when cs='0' else '0';

mosi_buf<=dataO(7) when (csf763='0' and (wr_n'event and wr_n='1'));
mosi<='1' when mosi_buf='1' else '0';

miso_buf(7 downto 0)<=miso_buf(6 downto 0) & miso when (sck_buf'event and sck_buf='0');

sck<='1' when sck_buf='1' else '0';

process(wr_n,rd_n,csf763)
begin
 if csf763='0' and (wr_n'event and wr_n='1') then
  sck_buf<='0';
 end if;
 if (rd_n='0') then
  sck_buf<='1';
 end if;
end process;

---------------------------------------USART (RS-232)--------------------------------------     
ip_uart<=dataO;          
rx_reg<=op_uart when (eoc'event and eoc='1'); 

process(clock,csf764,wr_n,uart_rdy)
begin
if (clock'event and clock='1') then
 if (csf764='0' and wr_n='0') then          
  uart_wr<='1';
 elsif uart_rdy='1' then
  uart_wr<='0';
 end if;
end if; 
end process;

process(uart_del,uart_speed,clock)
begin
 case uart_speed is
  when "11"=>uart_clk<=clock;
  when "10"=>uart_clk<=uart_del(0);
  when "01"=>uart_clk<=uart_del(1);
  when "00"=>uart_clk<=uart_del(2);
 end case;
end process;
 
uart_del<=uart_del+1 when (clock'event and clock='1');   

process(csf765,wr_n,res_n,dataO)
begin
 if res_n='0' then
  rx_int<='0';
  uart_speed<="11";
 elsif csf765='0' and (wr_n'event and wr_n='1') then
   rx_int<=dataO(6);
   uart_speed<=dataO(1 downto 0);  
 end if;
end process;
 
process(eoc,csf764,rd_n)
begin
 if (eoc='1') then
  rx_status<='1';
 elsif csf764='0' and (rd_n'event and rd_n='1') then
  rx_status<='0';
 end if;
end process;   
 
-------------------------------------Data & Adress flow control-------------------------------------------------
--Adress commutation--
process(hcnt,vcnt,sel,clock,a_buff,f9,fa,fb,fbdis,top,csf5,pf501,pf502,fbfull,rom_reg,p4f)  
variable selector: std_logic_vector(2 downto 0);
begin
selector:= top & fbfull & p4f(2);
 case sel is
  when '1'=>a(15 downto 0)<=not(fa(1 downto 0)) & hcnt(8 downto 3) & vcnt(8 downto 1);
            a(16)<=clock;
            a17<='0';
            a18<='0';
  when '0'=>case fbdis & a_buff(15 downto 14) is
            when "000" =>a(15 downto 0)<=fb(1 downto 0)& a_buff(13 downto 0);
                         a(16)<=fb(2);
                         a17<='0';
                         a18<='0';
            when others=>case csf5 & a_buff(7 downto 0) is 
			              when "000000000"=>a(16 downto 0)<=rom_reg(0) & pf502 & pf501;
			                                a17<=rom_reg(1);
			                                a18<='0';			             
			              when others     =>a(15 downto 0)<=a_buff;
                                            case selector is
			                                 when "100"|"101"|"111"  =>a(16)<='0';
			                                                           a17<='0';
			                                                           a18<='0';
                                             when others             =>a(16)<=f9(0);
                                                                       a17<=f9(1);
                                                                       a18<=f9(2); 
			                                end case;			                                
			             end case;           
			end case;                    		  
  end case;
end process;

--Data commutation--
process(p4f,turbo_reg,rom_reg,portio,romsel,scan_key,vector,iorq_n,m1_n,mreq_n,portsel,rx_reg,uart_rdy,rx_status,prefix,csf764,csf765,csf767,csf768,csf769,fbfull,romd_d,a_buff,csf4,pf401,pf402,d,miso,miso_buf,csf763)
begin                 
if (m1_n='0' and iorq_n='0') then
 dataI<=vector;
 elsif (romsel='1' and fbfull='0' and p4f(1)='0' and mreq_n='0') then  
  dataI<=romd_d;
 elsif (portsel='1' or portio='1') then
  if (csf4='0' and a_buff(3 downto 0)="0001") then 
   dataI<=pf401; 
  elsif (csf4='0' and a_buff(3 downto 0)="0010") then 
   dataI(7 downto 0)<=pf402(2 downto 0) & "10000";
  elsif (csf763='0') then
   dataI<=miso_buf(6 downto 0) & miso;
  elsif (csf764='0') then
   dataI<=rx_reg;
  elsif (csf765='0') then
   dataI<=not(uart_rdy) & rx_status & "111111";
  elsif (csf768='0') then
   dataI<=scan_key;
  elsif (csf769='0') then
   dataI<=prefix & "000000"; 
  elsif (csf767='0') then
   dataI<=p4f(7) & turbo_reg & rom_reg & p4f(2 downto 0);         
  else dataI(7 downto 0)<=d;
  end if;
 else
   dataI(7 downto 0)<=d;
end if;
end process;
   
d(7 downto 0)<=dataO when (sel='0' and wr_n='0') else "ZZZZZZZZ";

----------------------------------------------Video system section-------------------------------------------

process(mode_vga,hcnt,clock)            --Horizontal sync--
begin
if (clock'event and clock='1') then
 case mode_vga is                          
  when '0'=>if (hcnt(9 downto 0)=436) then hsync<='0';
             elsif (hcnt(9 downto 0)=516) then hsync<='1'; 
            end if;
  when '1'=>if (hcnt(9 downto 0)=486) then hsync<='0';
             elsif (hcnt(9 downto 0)=566) then hsync<='1'; 
            end if;
 end case;
end if; 
end process;

process(clock,vcnt)                     --Vertical sync--
begin
if (clock'event and clock='1') then
 if vcnt(9 downto 1)=278 then vsync<='0';
  elsif vcnt(9 downto 1)=282 then vsync<='1';
 end if;
end if;
end process;                                           

process(clock,vcnt,mode_vga,hcnt)           --Blank--         
begin
if (clock'event and clock='1') then
 if (hcnt=0 and vcnt(9)='0') then blank<='1';
  elsif (hcnt(9 downto 5)="011"& mode_vga & mode_vga) then blank<='0';
 end if;
end if;
end process;  

---------------------------Video data read-------------------------
process(clock,sel,d)
begin
if sel='1' then
 if (clock'event and clock='1') then
  vid0<=d;
 end if;
end if;
end process;

process(clock,sel,d)
begin
if sel='1' then
 if (clock'event and clock='0') then
  vid1<=d;
 end if;
end if;
end process;

process(hcnt,vid2,vid3)   --Video data shift registers--
begin
case hcnt(2 downto 0) is
 when "000"=>vid<=vid2(7);
            vidc<=vid3(7); 
 when "001"=>vid<=vid2(6);
            vidc<=vid3(6);
 when "010"=>vid<=vid2(5);
            vidc<=vid3(5);
 when "011"=>vid<=vid2(4);
            vidc<=vid3(4);
 when "100"=>vid<=vid2(3);
            vidc<=vid3(3);
 when "101"=>vid<=vid2(2);
            vidc<=vid3(2);
 when "110"=>vid<=vid2(1);
            vidc<=vid3(1);
 when "111"=>vid<=vid2(0);
            vidc<=vid3(0);
end case;
end process;

process(hcnt,clock,vid0,vid1,blank)    --Prepare videodata for mux--
begin
 if hcnt(2 downto 0)="111" then
  if clock'event and clock='1' then
   vid2<=vid0;
   vid3<=vid1;
   blank1<=blank;
  end if;
 end if;
end process;    

process(f8,vid3,blank1,vid,vidc,fc)        --VideoMUX-- 
begin
if blank1='1' then
case f8 is
 when "0111" ! "0110" =>if (vid='1' and vid3(2)='1') or (vid='0' and vid3(6)='1') then r<='1'; else r<='0'; end if;
                        if (vid='1' and vid3(1)='1') or (vid='0' and vid3(5)='1') then g<='1'; else g<='0'; end if;
                        if (vid='1' and vid3(0)='1') or (vid='0' and vid3(4)='1') then b<='1'; else b<='0'; end if;
                        if (vid='1' and vid3(3)='1') or (vid='0' and vid3(7)='1') then i<='1'; else i<='0'; end if;
 when "0100" ! "0101" =>if (vid='0' and vidc='1') then r<='1'; else r<='0'; end if; 
                        if (vid='1' and vidc='0') then g<='1'; else g<='0'; end if;
                        if (vid='1' and vidc='1') then b<='1'; else b<='0'; end if;
                        i<='1';
 when "0000"          =>if vid='1' then g<='1'; else g<='0'; end if;
                        r<='0';
                        b<='0';
                        i<='1';
 when "0001"          =>if vid='1' then r<='1'; else r<='0'; end if;
                        if vid='1' then g<='1'; else g<='0'; end if;
                        if vid='0' then b<='1'; else b<='0'; end if; 
                        if vid='1' then i<='1'; else i<='0'; end if;
 when "1110" ! "1111" =>if (vid='1' and fc(2)='1') or (vid='0' and fc(6)='1') then r<='1'; else r<='0'; end if;
                        if (vid='1' and fc(1)='1') or (vid='0' and fc(5)='1') then g<='1'; else g<='0'; end if;
                        if (vid='1' and fc(0)='1') or (vid='0' and fc(4)='1') then b<='1'; else b<='0'; end if;
                        if (vid='1' and fc(3)='1') or (vid='0' and fc(7)='1') then i<='1'; else i<='0'; end if;                                                              
 when others          =>r<='0';
                        g<='0';
                        b<='0'; 
                        i<='1';
 end case;
else r<='0';
     g<='0';
     b<='0';
     i<='0'; 
end if; 
end process;

-------------------Output video signals---------------
h_sync<='0' when hsync='0' else '1';
v_sync<='0' when vsync='0' else '1';

process(clock,r,g,b,i)
begin
 if (clock'event and clock='0') then
  red   <= r;
  green <= g;
  blue  <= b;
  if (i='0') then
   bright<= '0';
  else 
   bright<= 'Z';
  end if;  
 end if;
end process;
 
-----------------------------------------------Component section---------------------------------------
transm:async_transmitter ----- USART transmitter ----
port map( 
   clk                  =>uart_clk, 
   TxD_start            =>uart_wr,
   TxD_data             =>ip_uart,
   TxD                  =>txd, 
   TxD_busy             =>uart_rdy  
    );

receiver:async_receiver ------ USART receiver ------
port map( 
   clk                  =>uart_clk, 
   RxD                  =>rxd,
   RxD_data_ready       =>eoc,  
   RxD_data             =>op_uart  
    );

orionkey:orionkeyboard  ---- PS2/Keyboard controller ----
port map(
	clk                 =>not(clock),
	reset               =>'0',
	res_k               =>res_key,
	turb_10             =>turbo_10,
	turb_5              =>turbo_5,
	turb_2              =>turbo_2,
	rom_s               =>rom_sel,
	cpm_s               =>hi_rom,
	ps2_clk             =>ps2_clk,
	ps2_data            =>ps2_data,
	rk_kb_scan          =>pf400,
	rk_kb_out           =>pf401,
	pref                =>prefix,
	key_rus_lat         =>pf402(2),
	key_us              =>pf402(1),
	key_ss              =>pf402(0),
	ind_rus_lat         =>'0',
	rk_kbo              =>scan_key,
	key_int				=>int_key
);

romd_altera:lpm_rom1 --------- alteraROM BIOS ---------------
port map(
		address		=>romd_a(11 downto 0),
		clock		=>not(clock),
		clken		=>'1',		
		q		    =>romd_d(7 downto 0)
);

t80inst:T80s	     --------- Z80 core (T80) -----------
port map (
			M1_n           => m1_n,
			MREQ_n         => mreq_n,
			IORQ_n         => iorq_n,
			RD_n           => rd_n,
			WR_n           => wr_n,
			RFSH_n         => open,
			HALT_n         => open,
			WAIT_n         => wait_cpu,
			INT_n          => int_n,
			NMI_n          => '1',
			RESET_n        => res_n,
			BUSRQ_n        => '1',
			BUSAK_n        => open,
			CLK_n          => clk_cpu,
			A(15 downto 0) => a_buff(15 downto 0),
			DI             => dataI,
			DO             => dataO
		);

end vga_arch;