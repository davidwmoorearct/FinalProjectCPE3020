-------------------------------------------------------------------
-- Lab 04
-- David W. Moore & Nate Powell
--
-- Test bench for TransferController. Simulates a clock signal 
-- and tests a reasonable number of possible input combinations.
-- There are no inputs or outputs.
--------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TransferController_TB is
end TransferController_TB;

architecture TransferController_TB_ARCH of TransferController_TB is
   signal     clock         :  STD_LOGIC := '0';
   signal     reset       :  STD_LOGIC := '0';
   signal     tx_out      : STD_LOGIC;
   signal     busy        :  STD_LOGIC;
   signal     activePatternBack : std_logic_vector(2 downto 0) := "000";
   signal     activePatternBall : std_logic_vector(2 downto 0) := "000";
   signal     moveLeft          : std_logic;
   signal     moveRight         : std_logic;
   signal     sevenSegs : std_logic_vector(6 downto 0);
   signal     anodes : std_logic_vector(3 downto 0);
   
    component TransferController is
    generic (
    NUMLIGHTS: integer
    );
    Port (
        clock         : in  STD_LOGIC; -- 100MHz
        reset         : in  STD_LOGIC;
        activePatternBack : in std_logic_vector(2 downto 0);
        activePatternBall : in std_logic_vector(2 downto 0);
        moveLeft        : in std_logic;
        moveRight       : in std_logic;
        tx_out        : out STD_LOGIC;
        busy          : out STD_LOGIC;
        sevenSegs     : out STD_LOGIC_VECTOR (6 downto 0);
        anodes        : out STD_LOGIC_VECTOR (3 downto 0)
    );
   end component; 
begin
    UUT: TransferController 
    generic map (
    NUMLIGHTS => 1
    )
    port map(
        clock => clock,
        reset => reset,
        activePatternBack => activePatternBack,
        activePatternBall => activePatternBall,
        moveLeft => moveLeft,
        moveRight => moveRight,
        sevenSegs => sevenSegs,
        anodes => anodes,
        tx_out => tx_out,
        busy => busy
);
    CLK_GEN: process
    begin
        clock <= '0'; wait for 5 ns;
        clock <= '1'; wait for 5 ns;
    end process;
    
    DataTest: process
    begin
        -- Reset
        reset <= '1'; wait for 100 ns;
        reset <= '0'; wait for 100 ns;
        for i in 7 downto 0 loop
            activePatternBall <= std_logic_vector(to_unsigned(i, 3));
            activePatternBack <= std_logic_vector(to_unsigned(i, 3)); 
            wait for 40 ms; -- Increased from 10ms
            moveLeft <= '1';
            wait for 5ms;
            moveLeft <= '0';
            wait for 5ms;
        end loop;
        wait;
    end process;
end TransferController_TB_ARCH;
