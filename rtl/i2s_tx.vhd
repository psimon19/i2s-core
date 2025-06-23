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
port (
    mclk  : in std_logic;
    lrck  : in std_logic;
    sclk  : in std_logic;
    sdout : in std_logic;
    ws  : in std_logic;
    sd  : in std_logic
);
end i2s_tx;

architecture Behavioral of i2s_tx is

begin


end Behavioral;
