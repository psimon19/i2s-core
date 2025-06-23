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

entity i2s_tb is
end i2s_tb;

architecture Behavioral of i2s_tb is

-- System clock/reset
signal axis_clk      : std_logic := '0';
signal axis_rstn     : std_logic := '0';

-- I2S interface
signal mclk          : std_logic := '0';
signal lrck          : std_logic := '0';
signal sclk          : std_logic := '0';
signal sdout         : std_logic := '0';

-- Logic interface
signal m_axis_rdata  : std_logic_vector(31 downto 0);
signal m_axis_rvalid : std_logic;
signal m_axis_rready : std_logic := '1';
signal m_axis_rlast  : std_logic;

constant AXIS_CLKDIV : time := 44.265415430924 ns; -- 22.591 MHz
constant I2S_CLKDIV  : time := 11337.868480726 ns; -- 88.2 KHz


begin


i2s_rs_DUT : entity work.i2s_rx(Behavioral)
generic map (
    I2S_BIT_WIDTH  => 24
)
port map (
    -- System clock/reset
    axis_clk      => axis_clk,
    axis_rstn     => axis_rstn,

    -- I2S interface
    mclk          => mclk,
    lrck          => lrck,
    sclk          => sclk,
    sdout         => sdout,
    
    -- Logic interface
    m_axis_rdata  => m_axis_rdata,
    m_axis_rvalid => m_axis_rvalid,
    m_axis_rready => m_axis_rready,
    m_axis_rlast  => m_axis_rlast
);

AXIS_CLK_STIM : process
begin
    axis_clk <= not axis_clk;
    wait for AXIS_CLKDIV;
end process;

AXIS_RST_STIM : process
begin
    wait for AXIS_CLKDIV*100;
    wait until rising_edge(axis_clk);
    axis_rstn <= '1';
    wait;
end process;

I2S_CLK_STIM : process
begin
    mclk <= not mclk;
    wait for I2S_CLKDIV;
end process;

I2S_DATA_STIM : process
begin
    for i in 0 to 10000 loop
        lrck <= not lrck;
        for j in 0 to 23 loop
            sclk  <= '1';
            sdout <= not sdout;
            wait until rising_edge(mclk);
            sclk  <= '0';
            wait until rising_edge(mclk);
        end loop;
    end loop;
    wait;
end process;

end Behavioral;
