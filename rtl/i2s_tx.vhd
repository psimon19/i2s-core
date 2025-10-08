----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/22/2025 10:29:56 AM
-- Design Name: 
-- Module Name: i2s-tx - Behavioral
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

entity i2s_tx is
generic (
    I2S_BIT_WIDTH  : integer range 16 to 32 := 24
);
port (
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
end i2s_tx;

architecture Behavioral of i2s_tx is

signal axis_count : unsigned(3 downto 0);
signal data_sr    : std_logic_vector(I2S_BIT_WIDTH*2-1 downto 0);
signal vld_sr     : std_logic_vector(1 downto 0);
signal last_sr    : std_logic_vector(1 downto 0);

signal m_axis_wdata_q  : std_logic_vector(31 downto 0);
signal m_axis_wvalid_q : std_logic;
signal m_axis_wlast_q  : std_logic;

signal sclk_i     : std_logic;
signal sclk_q     : std_logic;
signal sclk_ctr   : unsigned(2 downto 0);
signal lrck_ctr   : unsigned(5 downto 0);
signal data       : std_logic_vector(I2S_BIT_WIDTH-1 downto 0);
signal din_sr     : std_logic_vector(I2S_BIT_WIDTH-1 downto 0);
signal din_rdy    : std_logic;
signal din_rdy_sr : std_logic_vector(1 downto 0);
signal din_vld    : std_logic;

begin

m_axis_wready <= din_rdy;

I2S_SCLK_CONTROL : process(mclk)
begin
    if (rising_edge(mclk)) then
        if (mrst = '1') then
            sclk_ctr <= (others => '0');
            sclk_i   <= '0';
            sclk_q   <= '0';
            din_rdy  <= '0';
        else
            sclk_q   <= sclk_i;
            
            if (sclk_ctr = 7) then
                sclk_ctr <= "000";
                din_rdy  <= '0';
            elsif (sclk_ctr = 6) then
                sclk_ctr <= sclk_ctr + 1;
                din_rdy  <= '1';
            else          
                sclk_ctr <= sclk_ctr + 1;
                din_rdy  <= '0';
            end if;
            
            if (sclk_ctr = "000") then
                sclk_i <= not sclk_i;
            end if;
        end if;
    end if;
end process;

I2S_LRCK_CONTROL : process(mclk)
begin
    if (rising_edge(mclk)) then
        if (mrst = '1') then
            lrck_ctr <= (others => '0');
        else
            if (sclk_i = '1' and sclk_q = '0') then
                if (m_axis_wvalid = '1' or lrck_ctr = 23) then
                    lrck_ctr <= (others => '0');
                else
                    lrck_ctr <= lrck_ctr + 1;
                end if;
            end if;
        end if;
    end if;
end process;

REG_VLD : process(mclk)
begin
    if (rising_edge(mclk)) then
        if (m_axis_wvalid = '1') then
            data <= m_axis_wdata(I2S_BIT_WIDTH-1 downto 0);
            lrck <= m_axis_wlast;
        end if;      
    end if;
end process;

SDIN_GEN : process(mclk)
begin
    if (sclk_i = '0' and sclk_q = '1') then
        sdin <= data(to_integer(lrck_ctr));
    end if;
end process;

sclk <= sclk_q;

end Behavioral;
