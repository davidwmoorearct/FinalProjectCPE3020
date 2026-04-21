------------------------------------------------------------------------------------------
-- Lab 03
-- David W. Moore
--
-- Basys3 Wrapper for MovingLED
-- Description:
-- This entity serves as the top-level wrapper, mapping the internal MovingLED
-- logic to the physical hardware of the Basys3 board.
-- Inputs:
-- 'clk'      : System clock signal (100MHz).
-- 'btnC'     : Center pushbutton to act as reset.
-- 'btnL'     : Left pushbutton (BTNL) to move the LED left.
-- 'btnR'     : Right pushbutton (BTNR) to move the LED right.
-- Outputs:
-- 'led'      : 16-bit vector for board LEDs; used to display patterns from MovingLED.
-- 'seg'      : 7-bit vector for the Seven Segment Display segments (a through g).
-- 'an'       : 4-bit vector for the display anodes; used to enable digits 0, 1, and 3.
------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TransferController_BASYS3 is
    Port (
    clk: in std_logic;
    btnD: in std_logic;
    btnL: in std_logic;
    btnR: in std_logic;
    sw: in std_logic_vector(15 downto 0);
    led: out std_logic_vector(1 downto 0);
    JA: out std_logic_vector(0 downto 0);
    seg: out std_logic_vector(6 downto 0);
    an:  out std_logic_vector(3 downto 0)
 );
end TransferController_BASYS3;

architecture TransferController_BASYS3_ARCH of TransferController_BASYS3 is
    signal clock: std_logic := '0';
    signal reset: std_logic := '0';
    signal moveLeft: std_logic;
    signal moveRight: std_logic;
    signal busy: std_logic := '0';
    signal tx_out: std_logic := '0';
    signal activePatternBack: std_logic_vector(2 downto 0);
    signal activePatternBall: std_logic_vector(2 downto 0);
    component TransferController is
    generic (
    NUMLIGHTS: integer
    );
    Port (
        clock         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        moveLeft:     in std_logic;
        moveRight:    in std_logic;
        activePatternBack : in std_logic_vector(2 downto 0);
        activePatternBall : in std_logic_vector (2 downto 0);
        tx_out      : out STD_LOGIC;
        busy        : out STD_LOGIC;
        sevenSegs    : out STD_LOGIC_VECTOR (6 downto 0);
        anodes       : out STD_LOGIC_VECTOR (3 downto 0)
    );
    end component;
begin

    UUT: TransferController 
    generic map(
    NUMLIGHTS => 10
    )
    port map(
        clock => clk,
        reset => btnD,
        moveLeft => btnL,
        moveRight => btnR,
        activePatternBack => sw(2 downto 0),
        activePatternBall  => sw(15 downto 13),
        tx_out => JA(0),
        busy => led(1),
        sevenSegs => seg,
        anodes => an
    );
end TransferController_BASYS3_ARCH;
