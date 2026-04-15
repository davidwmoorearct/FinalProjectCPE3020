------------------------------------------------------------------------------------------
-- Lab 04
-- David W. Moore & Nate Powell
--
-- Basys3 Wrapper for TransferController
-- 
-- Inputs:
-- 'clk'           : System clock signal (100MHz).
-- 'btnD'          : Reset.
-- 'sw'            : 3 switches to set a 
--                   3 bit std_logic_vector that is passed into a multiplexer to acquire 
--                   the 24-bit data to transmit to the external LED.
-- 'btnC'          : Button to transmit data to the external LED.
-- Outputs:
-- 'led"           : Used for some status indicators, but never displays in a way visible
--                   to the human eye because of how fast it pulses.
-- 'JA0'           : Port used for the serialized output according to WS2812B standard.
-- 'busy'          : Signal that goes 1 when processing data and 0 when not.  
-- 'seg'           : Segements of 7 Seg Display to be lit.
-- 'an'            : Which anodes of the 7 Seg Display should be active.
------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TransferController_BASYS3 is
    Port (
    clk: in std_logic;
    btnD: in std_logic;
    btnC: in std_logic;
    sw: in std_logic_vector(2 downto 0);
    led: out std_logic_vector(1 downto 0);
    JA: out std_logic_vector(0 downto 0);
    seg: out std_logic_vector(6 downto 0);
    an:  out std_logic_vector(3 downto 0)
 );
end TransferController_BASYS3;

architecture TransferController_BASYS3_ARCH of TransferController_BASYS3 is
    signal clock: std_logic := '0';
    signal reset: std_logic := '0';
    signal txEn: std_logic := '0';
    signal fifoFull: std_logic := '0';
    signal busy: std_logic := '0';
    signal tx_out: std_logic := '0';
    signal activePattern: std_logic_vector(2 downto 0);
    component TransferController is
    generic (
    NUMLIGHTS: integer
    );
    Port (
        clock         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        txEn        : in  STD_LOGIC;
        activePattern : in std_logic_vector(2 downto 0);
        fifoFull    : out STD_LOGIC;
        tx_out      : out STD_LOGIC;
        busy        : out STD_LOGIC;
        sevenSegs    : out STD_LOGIC_VECTOR (6 downto 0);
        anodes       : out STD_LOGIC_VECTOR (3 downto 0)
    );
    end component;
begin

    UUT: TransferController 
    generic map(
    NUMLIGHTS => 1
    )
    port map(
        clock => clk,
        reset => btnD,
        txEn => btnC,
        activePattern => sw(2 downto 0),
        tx_out => JA(0),
        busy => led(1),
        fifoFull => led(0),
        sevenSegs => seg,
        anodes => an
    );
end TransferController_BASYS3_ARCH;
