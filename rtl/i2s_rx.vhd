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
-- https://digilent.com/reference/pmod/pmodi2s2/reference-manual?srsltid=AfmBOoppq5CNG-zAdzbM98GmcUgOWnSfxcpTNOjsh9ib9urGnHV_YgRL

----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity i2s_rx is
generic (
    I2S_BIT_WIDTH  : integer range 16 to 32 := 24
);
port (
    mclk          : in std_logic;
    mrst          : in std_logic;
    lrck          : in std_logic;
    sclk          : in std_logic;
    sdout         : in std_logic;
    
    -- Logic interface
    m_axis_rdata  : out std_logic_vector(31 downto 0);
    m_axis_rvalid : out std_logic;
    m_axis_rready : in  std_logic;
    m_axis_rlast  : out std_logic
);
end i2s_rx;

architecture Behavioral of i2s_rx is

signal start        : std_logic; -- synchronizes timer with lrck

signal sclk_q       : std_logic;
signal lrck_q1      : std_logic;
signal lrck_q2      : std_logic;
signal next_lrck    : std_logic := '0';
signal i2s_sd_sr    : std_logic_vector(I2S_BIT_WIDTH-1 downto 0);
signal i2s_sd_vld   : std_logic;
signal i2s_sd_vld_q : std_logic;
signal i2s_sd_cnt   : integer range 0 to I2S_BIT_WIDTH-1;

signal i2s_data_cdc : std_logic_vector(I2S_BIT_WIDTH*2-1 downto 0);
signal i2s_data_q   : std_logic_vector(I2S_BIT_WIDTH*2-1 downto 0);
signal i2s_data     : std_logic_vector(I2S_BIT_WIDTH-1 downto 0);
signal i2s_vld_cdc  : std_logic_vector(1 downto 0);
signal i2s_vld_q    : std_logic;
signal i2s_vld      : std_logic;

signal m_axis_rlast_i : std_logic := '0';

begin
    
    -------------------------------------------------------------------
    ------------------------ I2S Clock Domain -------------------------
    -------------------------------------------------------------------
    
    GEN_START : process(mclk)
    begin
        if (rising_edge(mclk)) then
            if (mrst = '1') then
                start <= '0';
            elsif (lrck_q2 = '0' and lrck_q1 = '1') then
                start <= '1';
            end if;
        end if;
    end process;
    
    -- Register the sclk to detect rising edge
    REG_I2S : process(mclk)
    begin
       if (rising_edge(mclk)) then
           sclk_q  <= sclk;
           if (sclk = '0' and sclk_q = '1') then
                lrck_q1 <= lrck;
            end if;
           lrck_q2 <= lrck_q1;
       end if;     
    end process;

    -- Shift in left/right
    SHIFT_DATA : process(mclk)
    begin
        if (rising_edge(mclk)) then
            -- Clock in data on falling edge of sclk
            if (sclk = '0' and sclk_q = '1') then
                i2s_sd_sr  <= i2s_sd_sr(I2S_BIT_WIDTH-2 downto 0) & sdout;
            end if;
         end if;
    end process;
    
    GEN_VLD : process(mclk)
    begin
        if (rising_edge(mclk)) then
            if (mrst = '1') then
                i2s_sd_vld   <= '1';
                i2s_sd_vld_q <= '1';
            elsif (sclk = '0' and sclk_q = '1') then 
                if (i2s_sd_cnt = I2S_BIT_WIDTH-1) then
                    i2s_sd_vld <= '1';
                else
                    i2s_sd_vld <= '0';
                end if;
            else
                i2s_sd_vld <= '0';
            end if;
        end if;  
    end process;
    
    I2S_COUNT : process(mclk)
    begin
        if (rising_edge(mclk)) then
            if (sclk = '0' and sclk_q = '1') then
                if (i2s_sd_cnt = 23 or start = '0') then
                    i2s_sd_cnt <= 0;
                else
                    i2s_sd_cnt <= i2s_sd_cnt + 1;
                end if;
            end if;
        end if;
    end process;
    
    -------------------------------------------------------------------
    ------------------------ AXI Clock Domain -------------------------
    -------------------------------------------------------------------
    
    i2s_vld  <= i2s_sd_vld;
    
    m_axis_rlast <= m_axis_rlast_i;
    
    AXIS_OUT: process(mclk)
    begin
        if (rising_edge(mclk)) then
            i2s_data <= i2s_sd_sr;
            -- Each frame contains R + L audio channel
            if (i2s_sd_vld = '0' and i2s_vld_q = '1') then
                m_axis_rlast_i <= not m_axis_rlast_i;
            end if;
            if (I2S_BIT_WIDTH = 32) then
                m_axis_rdata  <= i2s_data;
            else
                m_axis_rdata  <= (32-I2S_BIT_WIDTH-1 downto 0 => '0') & i2s_data;
            end if;          
        end if;
    end process;
    
    AXIS_OUT_VLD : process(mclk)
    begin
        if (rising_edge(mclk)) then
            if (mrst = '1') then
                m_axis_rvalid <= '0';
                i2s_vld_q     <= '0';
            else
                i2s_vld_q     <= i2s_vld;
                m_axis_rvalid <= i2s_vld and (not i2s_vld_q);
            end if;
        end if;
    end process;

end Behavioral;
