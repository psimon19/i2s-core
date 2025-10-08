----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/28/2025 10:58:00 AM
-- Design Name: 
-- Module Name: audio_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity audio_top is
port (
    clk_in     : in std_logic; -- 100 MHz clock
    rst_in     : in std_logic; -- Tied to center button
    adin_mclk  : out std_logic;
    adin_sclk  : out std_logic;
    adin_lrck  : out std_logic;
    adin_sdout : in std_logic;
    adout_mclk : out std_logic;
    adout_sclk : out std_logic;
    adout_lrck : out std_logic;
    adout_sdin : out std_logic;
    
    led        : out std_logic_vector(1 downto 0)
);
end audio_top;

architecture Behavioral of audio_top is

component i2s_tx
generic (
    I2S_BIT_WIDTH  : integer range 16 to 32 := 24
);
port (
    -- I2S interface
    mclk          : in std_logic;
    mrst          : in std_logic;
    lrck          : out std_logic;
    sclk          : out std_logic;
    sdin          : out std_logic;
    
    -- Logic interface
    m_axis_wdata  : in  std_logic_vector(31 downto 0);
    m_axis_wvalid : in  std_logic;
    m_axis_wready : out std_logic;
    m_axis_wlast  : in  std_logic
);
end component;

component i2s_clk_gen
port
 (-- Clock in ports
  -- Clock out ports
  axi_clk       : out    std_logic;
  mclk          : out    std_logic;
  -- Status and control signals
  reset         : in     std_logic;
  locked        : out    std_logic;
  clk_in        : in     std_logic
 );
end component;

signal clk        : std_logic;
signal axi_clk    : std_logic;
signal axi_rst    : std_logic;
signal axi_rst_sr : std_logic_vector(1 downto 0);

-- I2S assignments
signal mclk         : std_logic;
signal mclk_locked  : std_logic;
signal mrst  : std_logic;
signal mrst_sr : std_logic_vector(1 downto 0);

signal adin_lrck_i  : std_logic;
signal adin_sclk_i  : std_logic;
signal adin_sclk_r  : std_logic;
signal adin_sdout_i : std_logic;
 
signal i2s_sclk_ctr : unsigned(15 downto 0);
signal i2s_lrck_ctr : unsigned(15 downto 0);
signal debug_timer  : integer;
signal timer_led    : std_logic := '0';

-- AXI
signal m_axis_rdata  : std_logic_vector(31 downto 0);
signal m_axis_rvalid : std_logic;
signal m_axis_rready : std_logic;
signal m_axis_rlast  : std_logic;

begin

led(0) <= mclk_locked;

i2s_clk_gen_inst : i2s_clk_gen
   port map ( 
  -- Clock out ports  
   axi_clk => axi_clk,
   mclk    => mclk,
  -- Status and control signals                
   reset   => rst_in,
   locked  => mclk_locked,
   -- Clock in ports
   clk_in  => clk_in
 );

mrst_bridge : process(mclk, rst_in)
begin
    if (rst_in = '1') then
        mrst_sr <= "11";
    elsif (rising_edge(mclk)) then
        mrst_sr <= mrst_sr(0) & '0';
    end if; 
end process;
mrst <= mrst_sr(1);

--------------------------------------------
------------- LOOPBACK TEST ----------------
--------------------------------------------
I2S_SCLK_CONTROL : process(mclk)
begin
    if (rising_edge(mclk)) then
        if (mrst = '1') then
            i2s_sclk_ctr <= (others => '0');
            adin_sclk_i <= '0';
            adin_sclk_r <= '0';
        else
            adin_sclk_r  <= adin_sclk_i;
            i2s_sclk_ctr <= i2s_sclk_ctr + 1;
            
            if (i2s_sclk_ctr(2 downto 0) = "000") then
                adin_sclk_i <= not adin_sclk_i;
            end if;
        end if;
    end if;
end process;

I2S_LRCK_CONTROL : process(mclk)
begin
    if (rising_edge(mclk)) then
        if (mrst = '1') then
            i2s_lrck_ctr <= (others => '0');
            adin_lrck_i <= '0';
        else
            if (adin_sclk_i = '1' and adin_sclk_r = '0') then
                if (i2s_lrck_ctr = 23) then
                    adin_lrck_i <= not adin_lrck_i;
                    i2s_lrck_ctr <= (others => '0');
                else
                    i2s_lrck_ctr <= i2s_lrck_ctr + 1;
                end if;
            end if;
        end if;
    end if;
end process;

adin_sdout_i <= adin_sdout;

BLINK : process(mclk)
begin
    if (rising_edge(mclk)) then
        if (mrst = '1') then
            debug_timer  <= 0;
            timer_led    <= '0';
        else
            debug_timer <= debug_timer + 1;
            
            if (debug_timer = 22580000) then
                debug_timer <= 0;
                timer_led   <= not timer_led;
            end if;
        end if;
    end if;
end process;

led(1) <= timer_led;

-- Toggle outputs
--adin_sclk_i  <= adout_sclk_r;
--adin_lrck_i  <= adout_lrck_i;

adin_sclk    <= adin_sclk_r;
adin_lrck    <= adin_lrck_i;
--adout_sclk   <= adout_sclk_r;
--adout_lrck   <= adout_lrck_i;


adin_mclk    <= mclk;
adout_mclk   <= mclk;

i2s_rx_INST : entity work.i2s_rx(Behavioral)
generic map(
    I2S_BIT_WIDTH => 24
)
port map (
    mclk          => mclk,
    mrst          => mrst,
    lrck          => adin_lrck_i,
    sclk          => adin_sclk_r,
    sdout         => adin_sdout_i,

    m_axis_rdata  => m_axis_rdata,
    m_axis_rvalid => m_axis_rvalid,
    m_axis_rready => m_axis_rready,
    m_axis_rlast  => m_axis_rlast
);

i2s_tx_INST : i2s_tx
generic map (
    I2S_BIT_WIDTH => 24
)
port map (
    mclk          => mclk,
    mrst          => mrst,
    lrck          => adout_lrck,
    sclk          => adout_sclk,
    sdin          => adout_sdin,

    m_axis_wdata  => m_axis_rdata,
    m_axis_wvalid => m_axis_rvalid,
    m_axis_wready => m_axis_rready,
    m_axis_wlast  => m_axis_rlast
);

end Behavioral;
