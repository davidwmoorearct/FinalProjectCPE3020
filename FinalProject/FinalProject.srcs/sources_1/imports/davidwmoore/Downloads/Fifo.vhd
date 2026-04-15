library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--*****************************************************************************
--*
--* Name: Fifo
--* Designer: Scott Tippens
--*
--*     Create a basic FIFO implementation with generic depth and width.  Basic
--*     status information provided for full and empty fifo.
--*
--*     When the fifo is not empty, 'dataOut' represents the value in the fifo
--*     pointed to by the current 'readIndex'.  Trying to read from an empty
--*     fifo or trying to write to a full fifo results in no change.
--* 
--*     The fifo can be declared as any size as long as the target device has
--*     the required resources.
--*
--*****************************************************************************

entity Fifo is
	generic (
		WIDTH:  natural;    --size of each fifo register
		DEPTH:  integer     --number of registers in the fifo
		); 
	port (
		reset: in std_logic;
		clock: in std_logic;

		writeEn: in  std_logic;    --initiates write to fifo
 		readEn:  in  std_logic;    --removes next fifo data value
 		dataIn:  in  std_logic_vector(WIDTH-1 downto 0);
 		
		fifoFull:   out std_logic;    --fifo is full
		fifoEmpty:  out std_logic;    --fifo is empty
		dataOut:    out std_logic_vector(WIDTH-1 downto 0)
		);
end Fifo;



architecture Fifo_ARCH of Fifo is

	----general-definitions--------------------------------------------CONSTANTS--
	constant ACTIVE: std_logic := '1';

	----fifo-registers------------------------------------------------------FIFO--
	type fifoData_t is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
	signal fifoData: fifoData_t := (others => (others => '0'));

	----indexes-and-storage-counter------------------------------------REGISTERS--
	signal writeIndex:  integer range 0 to DEPTH-1 := 0;
	signal readIndex:   integer range 0 to DEPTH-1 := 0;
	signal count:       integer range 0 to 1 := 0;

	----status-----------------------------------------------------------SIGNALS--
	signal full:   std_logic;
	signal empty:  std_logic;


begin

	--============================================================================
	--  Update FIFO registers
	--============================================================================
	UPDATE_REGISTERS: process(reset, clock)
	begin
		if (reset=ACTIVE) then
			writeIndex <= 0;
			readIndex  <= 0;
			count      <= 0;
		elsif (rising_edge(clock)) then

			--handle-write-operation-and-control-rollover-------------------------
			if ( (writeEn=ACTIVE) and (readEn=not ACTIVE) and (full=not ACTIVE) ) then
				count <= count + 1;
				fifoData(writeIndex) <= dataIn;

				if (writeIndex=DEPTH-1) then
					writeIndex <= 0;
				else
					writeIndex <= writeIndex + 1;
				end if;
			end if;


			--handle-read-operation-and-control-rollover--------------------------
			if ( (readEn=ACTIVE) and (writeEn=not ACTIVE) and (empty=not ACTIVE) ) then
				count <= count - 1;

				if (readIndex=DEPTH-1) then
					readIndex <= 0;
				else
					readIndex <= readIndex + 1;
				end if;
			end if;
			
		end if;
	end process UPDATE_REGISTERS;



	--============================================================================
	--  Update Data and Status Outputs
	--============================================================================
	dataOut <= fifoData(readIndex);
	
	empty <= ACTIVE when (count=0) else not ACTIVE;
	fifoEmpty <= empty;
	
	full  <= ACTIVE when (count=DEPTH) else not ACTIVE;
	fifoFull <= full;
	

end Fifo_ARCH;
