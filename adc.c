/**
 *
 * ADC1->CR |= ADC_CR_ADSTART;
 *
 *	newPotValue = ADC1->DR; //checks adc value every loop
 *
 *	run the stuff above in main loop. below call before main loop
 */

void startADCPotent(void)
{
    //===================================================================================
    // 1. HARDWARE POWER & CLOCK SETUP (Must happen first!)
    //===================================================================================

    //--enable-resource-clocks-----------------------------------------------------------
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;        // enable GPIOA clock
    RCC->AHB2ENR |= RCC_AHB2ENR_ADCEN;          // enable ADC clock
    RCC->CCIPR &= ~RCC_CCIPR_ADCSEL;            // Clear the current ADC clock selection
    RCC->CCIPR |= (3U << RCC_CCIPR_ADCSEL_Pos); // Select System Clock (SYSCLK) as the source

    //--configure-pin-for-analog-input---------------------------------------------------
    GPIOA->MODER |= (3U << (0 * 2));            // analog mode
    GPIOA->PUPDR &= ~(3U << (0 * 2));           // no pull-up/pull-down
    GPIOA->ASCR |= GPIO_ASCR_ASC0;

    //--disable-adc-(just in case)-------------------------------------------------------
    if ((ADC1->CR & ADC_CR_ADEN) != 0)
    {
        ADC1->CR |= ADC_CR_ADDIS;               // disable if enabled
        while (ADC1->CR & ADC_CR_ADEN);         // wait until disabled
    }

    //--wake-up-from-deep-power-down-----------------------------------------------------
    ADC1->CR &= ~ADC_CR_DEEPPWD;                // had to add cause it wasnt working

    //--enable-internal-voltage-regulator------------------------------------------------
    ADC1->CR |= ADC_CR_ADVREGEN;
    SystemCoreClockUpdate();                    // update core clock value in case clock change
    delay_us(40);                               // wait for regulator to stabilize (>20us)


    //===================================================================================
    // 2. ADC CALIBRATION & CONFIGURATION
    //===================================================================================

    //--calibrate-adc--------------------------------------------------------------------
    ADC1->CR |= ADC_CR_ADCAL;                   // start calibration
    while (ADC1->CR & ADC_CR_ADCAL);            // wait until calibration has completed

    //--configure-adc--------------------------------------------------------------------
    ADC1->CFGR = (ADC_CFGR_JQDIS |              // injection queue disabled
                  ADC_CFGR_CONT  |
				  ADC_CFGR_OVRMOD);             // continuous conversion mode


    // disable DMA requests.......(ADC_CFGR_DMAEN=0)
    // 12-bit resolution..........(ADC_CFGR_RES=00)
    // data is right aligned......(ADC_CFGR_ALIGN=0)
    // hardware trigger disabled..(ADC_CFGR_EXTEN=00)
    // single conversion mode.....(ADC_CFGR_CONT=0)
    // disable discontinuous mode.(ADC_CFGR_DISCEN=0)
    // disable analog watchdog...(ADC_CFGR_AWD1EN=0)

    //--set-output-sampling-time-for-channel-5-------------------------------------------
    ADC1->SMPR1 = (ADC1->SMPR1 & ~(7u<<(5 * 3))) | (4u<<(5 * 3)); // 4.75 adc cycles

    //--set-the-channel-conversion-sequence----------------------------------------------
    ADC1->SQR1 = (5U << ADC_SQR1_SQ1_Pos);      // one conversion for channel 5 (L=0)


    //===================================================================================
    // 3. ENABLE AND START ADC
    //===================================================================================

    //--enable-the-adc-------------------------------------------------------------------
    ADC1->ISR |= ADC_ISR_ADRDY;                 // clear ready flag
    ADC1->CR |= ADC_CR_ADEN;                    // enable ADC
    while (!(ADC1->ISR & ADC_ISR_ADRDY));       // wait until ready

    ADC1->CR |= ADC_CR_ADSTART;
}

