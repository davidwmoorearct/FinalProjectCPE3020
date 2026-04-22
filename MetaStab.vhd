------------------------------------------------------------------------------------------
-- Lab 04
-- David W. Moore & Nate Powell
--
-- Very simple two flip flop metastabilizer, with a monoprocedure to do all the meta-
-- stabilization at once for the project.
------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package MetaStab is
procedure META_STABILITY 
(
signal valueToStabilize: in STD_LOGIC; 
signal clock: in STD_LOGIC;
signal reset: in STD_LOGIC;
signal MetaStableOutput: out STD_LOGIC;
signal NonMetaStableOutput: inout STD_LOGIC
);
procedure STABILIZE_INTERFACE 
(
    signal clock               : in  STD_LOGIC;
    signal reset               : in  STD_LOGIC;
    -- Raw Inputs
    signal moveLeft            : in  STD_LOGIC;
    signal moveRight           : in  STD_LOGIC;
    signal activePatternBack   : in  STD_LOGIC_VECTOR(2 downto 0);
    signal activePatternBall   : in  STD_LOGIC_VECTOR(2 downto 0);
    -- Intermediate Stage (inout required for the META_STABILITY call)
    signal moveLeft_mid        : inout STD_LOGIC;
    signal moveRight_mid       : inout STD_LOGIC;
    signal activePatternBack_mid: inout STD_LOGIC_VECTOR(2 downto 0);
    signal activePatternBall_mid: inout STD_LOGIC_VECTOR(2 downto 0);
    -- Final Synchronized Outputs
    signal moveLeft_sync       : out STD_LOGIC;
    signal moveRight_sync      : out STD_LOGIC;
    signal activePatternBack_sync: out STD_LOGIC_VECTOR(2 downto 0);
    signal activePatternBall_sync: out STD_LOGIC_VECTOR(2 downto 0)
);

end MetaStab;

package body MetaStab is


procedure META_STABILITY 
(
signal valueToStabilize: in STD_LOGIC; 
signal clock: in STD_LOGIC;
signal reset: in STD_LOGIC;
signal MetaStableOutput: out STD_LOGIC;
signal NonMetaStableOutput: inout STD_LOGIC
) is
begin
if (reset = '1') then
	MetaStableOutput <= '0';
	NonMetaStableOutput <= '0';
elsif (rising_edge(clock)) then
	MetaStableOutput <= NonMetaStableOutput;
	NonMetaStableOutput <= valueToStabilize;
end if;
end procedure;


procedure STABILIZE_INTERFACE 
(
    signal clock               : in  STD_LOGIC;
    signal reset               : in  STD_LOGIC;
    -- Raw Inputs
    signal moveLeft            : in  STD_LOGIC;
    signal moveRight           : in  STD_LOGIC;
    signal activePatternBack   : in  STD_LOGIC_VECTOR(2 downto 0);
    signal activePatternBall   : in  STD_LOGIC_VECTOR(2 downto 0);
    -- Intermediate Stage (inout required for the META_STABILITY call)
    signal moveLeft_mid        : inout STD_LOGIC;
    signal moveRight_mid       : inout STD_LOGIC;
    signal activePatternBack_mid: inout STD_LOGIC_VECTOR(2 downto 0);
    signal activePatternBall_mid: inout STD_LOGIC_VECTOR(2 downto 0);
    -- Final Synchronized Outputs
    signal moveLeft_sync       : out STD_LOGIC;
    signal moveRight_sync      : out STD_LOGIC;
    signal activePatternBack_sync: out STD_LOGIC_VECTOR(2 downto 0);
    signal activePatternBall_sync: out STD_LOGIC_VECTOR(2 downto 0)
) is
begin
    -- Stabilize moveLeft
    META_STABILITY(moveLeft, clock, reset, moveLeft_sync, moveLeft_mid);
    
    -- Stabilize moveRight
    META_STABILITY(moveRight, clock, reset, moveRight_sync, moveRight_mid);
    
    -- Stabilize activePatternBack (3 bits)
    for i in 0 to 2 loop
        META_STABILITY(activePatternBack(i), clock, reset, activePatternBack_sync(i), activePatternBack_mid(i));
    end loop;
    
    -- Stabilize activePatternBall (3 bits)
    for i in 0 to 2 loop
        META_STABILITY(activePatternBall(i), clock, reset, activePatternBall_sync(i), activePatternBall_mid(i));
    end loop;
    
end procedure;


end package body MetaStab;
