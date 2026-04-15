------------------------------------------------------------------------------------------
-- Lab 04
-- David W. Moore & Nate Powell
--
-- TransferController
------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TransferController is
    generic (
        NUMLIGHTS: integer := 10 
    );
    Port (
        clock         : in  STD_LOGIC; -- 100MHz
        reset         : in  STD_LOGIC;
        txEn          : in  STD_LOGIC;
        activePattern : in std_logic_vector(2 downto 0);
        fifoFull      : out STD_LOGIC;
        tx_out        : out STD_LOGIC;
        busy          : out STD_LOGIC;
        sevenSegs     : out STD_LOGIC_VECTOR (6 downto 0);
        anodes        : out STD_LOGIC_VECTOR (3 downto 0)
    );
end TransferController;

architecture TransferController_ARCH of TransferController is

    component Fifo is
        generic (
            WIDTH:  natural;
            DEPTH:  integer
        ); 
        port (
            reset:     in  std_logic;
            clock:     in  std_logic;
            writeEn:   in  std_logic;
            readEn:    in  std_logic;
            dataIn:    in  std_logic_vector(WIDTH-1 downto 0);
            fifoFull:  out std_logic;
            fifoEmpty: out std_logic;
            dataOut:   out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;
    
    component SevenSegmentDriver is
        port(
            reset: in std_logic;
            clock: in std_logic;
            digit3, digit2, digit1, digit0 : in std_logic_vector(3 downto 0);
            blank3, blank2, blank1, blank0 : in std_logic;
            sevenSegs : out std_logic_vector(6 downto 0);
            anodes    : out std_logic_vector(3 downto 0)
        );
    end component;

    -- FIFO queue signals 
    signal fifo_data_out : std_logic_vector(23 downto 0);
    signal fifo_empty    : std_logic;
    signal fifo_read_en  : std_logic := '0';

    -- Timing Constants for 100MHz (10ns per tick)
    constant T0H : integer := 40;   constant T0L : integer := 85;
    constant T1H : integer := 80;   constant T1L : integer := 45;
    constant T_RES : integer := 6000; -- 60us Reset

    type state_type is (IDLE, FETCH, FETCH_WAIT, SEND_BIT, WAIT_T_HIGH, WAIT_T_LOW, NEXT_LED, LATCH);
    signal state : state_type := IDLE;
    
    signal bit_cnt     : integer range 0 to 24 := 0;
    signal ctr         : integer := 0;
    signal led_cnt     : integer range 0 to 255 := 0; 
    signal current_bit : std_logic;
    signal writeData   : std_logic_vector(23 downto 0);
    
    -- debouncing stuff
    signal debounce_ctr : integer range 0 to 2000000 := 0; 
    signal txEn_stable  : std_logic := '0';
    signal txEn_reg     : std_logic := '0';
    signal txEn_pulse   : std_logic := '0';
    signal outputPattern : std_logic_vector(3 downto 0);
    
begin

    U_FIFO_BUFFER : Fifo
        generic map (
            WIDTH => 24,
            DEPTH => 2
        )
        port map (
            reset     => reset,
            clock     => clock,
            writeEn   => txEn_pulse,
            readEn    => fifo_read_en,
            dataIn    => writeData,
            fifoFull  => fifoFull,
            fifoEmpty => fifo_empty,
            dataOut   => fifo_data_out
        );

    TRANSMITTER: process(clock, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            tx_out <= '0';
            busy <= '0';
            fifo_read_en <= '0';
            ctr <= 0;
            led_cnt <= 0;
        elsif rising_edge(clock) then
            case state is
                
                when IDLE =>
                    tx_out <= '0';
                    busy <= '0';
                    fifo_read_en <= '0';
                    led_cnt <= 0; 
                    
                    if fifo_empty = '0' then
                        busy <= '1';
                        fifo_read_en <= '1'; 
                        state <= FETCH;
                    end if;

                when FETCH =>
                    fifo_read_en <= '0';
                    bit_cnt <= 0;
                    state <= FETCH_WAIT;  

                when FETCH_WAIT =>
                    state <= SEND_BIT;    

                when SEND_BIT =>
                    if bit_cnt < 24 then
                        current_bit <= fifo_data_out(23 - bit_cnt);
                        tx_out <= '1';
                        ctr <= 0;
                        state <= WAIT_T_HIGH;
                    else
                        ctr <= 0;
                        if led_cnt < NUMLIGHTS - 1 then
                            led_cnt <= led_cnt + 1;
                            state <= NEXT_LED;
                        else
                            led_cnt <= 0;
                            state <= LATCH; 
                        end if;
                    end if;

                when WAIT_T_HIGH =>
                    ctr <= ctr + 1;
                    if (current_bit = '0' and ctr >= T0H) or (current_bit = '1' and ctr >= T1H) then
                        tx_out <= '0';
                        ctr <= 0;
                        state <= WAIT_T_LOW;
                    end if;

                when WAIT_T_LOW =>
                    ctr <= ctr + 1;
                    if (current_bit = '0' and ctr >= T0L) or (current_bit = '1' and ctr >= T1L) then
                        bit_cnt <= bit_cnt + 1;
                        state <= SEND_BIT;
                    end if;

                when NEXT_LED =>
                    if fifo_empty = '0' then
                        -- If a NEW color was pressed, fetch it
                        fifo_read_en <= '1';
                        state <= FETCH;
                    else
                        -- If repeating the SAME color, skip FETCH_WAIT so we 
                        -- don't overwrite our latched_color with empty FIFO garbage.
                        bit_cnt <= 0;
                        state <= SEND_BIT; 
                    end if;

                when LATCH =>
                    tx_out <= '0';
                    if ctr < T_RES then
                        ctr <= ctr + 1;
                    else
                        ctr <= 0;
                        state <= IDLE; 
                    end if;

                when others => state <= IDLE;
            end case;
        end if;
    end process;
    
    BUTTONDEBOUNCER: process(clock, reset)
    begin
        if rising_edge(clock) then
            if txEn /= txEn_stable then
                if debounce_ctr < 1000000 then 
                    debounce_ctr <= debounce_ctr + 1;
                else
                    txEn_stable <= txEn;
                    debounce_ctr <= 0;
                end if;
            else
                debounce_ctr <= 0;
            end if;

            txEn_reg <= txEn_stable;
        end if;
    end process;
    
    txEn_pulse <= txEn_stable and (not txEn_reg);

    LIGHTSELECTOR: with activePattern select
            writeData <= X"00FF00" when "000", -- Pure Red
                         X"FF0000" when "001", -- Pure Green
                         X"0000FF" when "010", -- Pure Blue
                         X"FFFF00" when "011", -- Yellow (G+R)
                         X"00FFFF" when "100", -- Magenta (R+B)
                         X"FF00FF" when "101", -- White-ish (Warm)
                         X"80FF00" when "110", -- Orange (Full R, Half G)
                         X"FFFFFF" when "111", -- Full White
                         X"000000" when others;    
    outputPattern <= '0'&activePattern;                        
    
    SEVSEG_DRIVER : SevenSegmentDriver
            port map (
                reset     => Reset,
                clock     => Clock,
                digit3    => "0000",
                digit2    => "0000",
                digit1    => "0000",
                digit0    => outputPattern,
                blank3    => '1',
                blank2    => '1',
                blank1    => '1',
                blank0    => '0',
                sevenSegs => sevenSegs,
                anodes    => anodes
        );
end TransferController_ARCH;