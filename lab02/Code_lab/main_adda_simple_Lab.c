/*********************************************************************

 @file      main_adda_simple_Lab.c (Svg, 11-Jul-2023)

 @brief     C.Module.Unidaq2-ADDA Test Program
 @author    D.SignT GmbH & Co. KG, A.Klemenz, modified for MSVC simulation by Svg
 @version   1.0
 @date      2018-01-31, Svg, Kpke : 13-Mar-25
 @target    C.Module.Unidaq2-ADDA
 @compiler  CCS
 @history   1.0 initial release 2018-01-31 by AK                   */

/***********************************************************************
  includes
 ***********************************************************************/
#include <BoardSupport/inc/unidaq2.h>       /**< Unidaq2-ADDA BIOS    */
#include <BoardSupport/inc/errors.h>        /**< Error Codes          */
#include <BoardSupport/drv/i2c.h>          /**< Unidaq2-ADDA I2C     */
#include <BoardSupport/drv/adda.h>          /**< Unidaq2-ADDA ADC DAC */

#include <Common/pru.h>        				  /**< PRU subsystem      */

#pragma DATA_SECTION (PRU_addaCode, ".const_slow");
#include <Common/PRU/PRU_adda_bin.h> 		  /**< PRU program code   */

#include <ti/pspiom/cslr/soc_C6747.h>         /**< 6747 peripherals   */
#include <ti/pspiom/cslr/cslr_gpio.h>         /**< GPIO               */

#include <math.h>							  /**< floating-point     */
//#include "FIR_filter_asm_sc.asm"
#include "FIR_normal_WS26_MOODLE.h"
//#include "fir_filter_sc.c"
#include "FIR_dec_poly0.h"
#include "FIR_dec_poly1.h"
#include "FIR_dec_poly2.h"
#include "FIR_dec_poly3.h"
#include "FIR_dec_poly4.h"
#include "FIR_kernel_MM.h"
/***********************************************************************
  defines
 ***********************************************************************/
// default ratio of sample rates for ADC and DAC
#define ADC_DIV 2
#define DAC_DIV 2

#define ADC_FSAMP (100000/ADC_DIV)
#define DAC_FSAMP (100000/DAC_DIV)

//#define SYSMSG_DBG_UART     /**< system messages via Debug UART       */
#define SYSMSG_CCS_CIO      /**< system messages via CCS CIO          */

#ifdef SYSMSG_CCS_CIO
#include <stdio.h>
#endif


#define MM 5
#define K_DELAYS 315
// PRU
#define	PRU_NUM		0			/**< the PRU to handle McASP (0 or 1) */


/***********************************************************************
  globals (don't touch)
 ***********************************************************************/
/*
  Global variables used in interrupts must be declared volatile.
  Place in L1DRAM (.data_crit section) to avoid cache data
  displacement and fastest access time.
 */
#pragma DATA_SECTION (g_i16Data, ".data_crit");

volatile int16_t g_i16Data[2];

PRU_addaOvly PRU_addaRegs = (PRU_addaOvly) (PRU0_DRAM + PRU_NUM * (PRU1_DRAM-PRU0_DRAM));

/***********************************************************************
  globals SP Lab 
 ***********************************************************************/

// Put your additional global variables here ...

short FIR_filter_sc(    short FIR_delays[],         // delay array
                        short FIR_coe[],            // coefficients
                        short int Ndelays,          // number of coeffs / delays
                        short x_n,                  // current input sample
                        int shft);                // use shft=15 as default parameter


/***********************************************************************
  end of globals SP Lab
 ***********************************************************************/

/*******************************************************************//**
  @brief	system message output on Debug UART or via Code Composer
  @param    pstr - pointer to string
  @return	-
 ***********************************************************************/
void System_puts (char *pstr)
{
#ifdef SYSMSG_DBG_UART
    /*******************************************************************
      locals
     *******************************************************************/
    char c;

    /*******************************************************************
      write to Debug UART
     *******************************************************************/
    while ((c = *pstr++) != 0)
    {
        while (DBG_write(c) != DBG_OK) ;
    }
#endif

#ifdef SYSMSG_CCS_CIO
    /*******************************************************************
      write to CCS CIO
     *******************************************************************/
    printf (pstr);
    fflush(stdout);
#endif
}

/*********************************************************************
  @brief    PRU interrupt for ADC
  @param    -
  @return   -
 ***********************************************************************/
__interrupt void adcInt (void)
{
    //  read ADC channels
    g_i16Data[0] = PRU_addaRegs->adc[0];
    g_i16Data[1] = PRU_addaRegs->adc[1];

    // ---------------------------------------------------------------------------------------------------------
    // Assignment 4.1
    //g_i16Data[0]=FIR_filter_sc(H_filt_FIR_normal,b_FIR_normal,N_delays_FIR_dki_normal,g_i16Data[0],15);
    // ---------------------------------------------------------------------------------------------------------


    // ---------------------------------------------------------------------------------------------------------
    // Assignment 4.2

    static int countAdcInt=0;
    static int inL =0;
    static int tau_count =0;

    static int y1=0,y1_part1=0,y1_part2=0,y1_part3=0,y1_part4=0,y1_part5=0;
    static int y2 = 0;
    static int y3=0;
    //,y3_part1=0,y3_part2=0,y3_part3=0,y3_part4=0,y3_part5=0;

    static short delay1=0, delay2=0, delay3=0, delay4=0;



    static short allpass_buf[K_DELAYS];

    int i;


    /*******************************************************************
    read two ADC channels and store in floating point format
    *******************************************************************/
    inL = g_i16Data[0]; // use channel 0 only
    // counter for ADC interrupt
    if (countAdcInt >= MM)
    countAdcInt = 0;
    // Polyphases of decimator filled in the order lambda = 0, 4, 3, 2, 1 and repeating,
    // at 0 sum is calculated and input to kernel filter.
    // Kernel filter and interpolation filter not yet implemented here.
    // distribute computations across 5 output ADC interrupts

    switch(countAdcInt){
    //---------------------------------- sample 0 ---------------------------------
    case 0:
        countAdcInt++;
        // compute polyphase FIR out and save
        y1_part1 = FIR_filter_sc(H_Delay0_DEC, b_FIR_dec_Poly0, N_DEC_DELAYS, (short)(inL), 15);

        y1 = y1_part1 + y1_part2 + y1_part3 + y1_part4 + y1_part5;

        //kernel
        y2 = FIR_filter_sc(H_DELAY_KERNEL,b_FIR_kernel, N_kernel, (short)(y1), 15);

        // interpolator
        y3 = FIR_filter_sc(H_Delay0_INT,b_FIR_dec_Poly0, N_DEC_DELAYS, (short)(y2), 15);

       break;
       //---------------------------------- sample 1 ---------------------------------
    case 1:
        countAdcInt++;

        y1_part2 = FIR_filter_sc(H_Delay4_DEC,
        b_FIR_dec_Poly4, N_DEC_DELAYS, inL, 15);
        //delay4 = inL;

        y3 = FIR_filter_sc(H_Delay1_INT,
                b_FIR_dec_Poly1, N_DEC_DELAYS, (short)(y2), 15);
        break;
        //---------------------------------- sample 2 ---------------------------------
    case 2:
        countAdcInt++;

        y1_part3 = FIR_filter_sc(H_Delay3_DEC,
        b_FIR_dec_Poly3, N_DEC_DELAYS, inL, 15);
        //delay3 = inL;

        y3 = FIR_filter_sc(H_Delay2_INT,
                b_FIR_dec_Poly2, N_DEC_DELAYS, (short)(y2), 15);
        break;
        //---------------------------------- sample 3 ---------------------------------
    case 3:
        countAdcInt++;

        y1_part4 = FIR_filter_sc(H_Delay2_DEC,
        b_FIR_dec_Poly2, N_DEC_DELAYS, inL, 15);
        //delay2 = inL;

        y3 = FIR_filter_sc(H_Delay3_INT,
                b_FIR_dec_Poly3, N_DEC_DELAYS, (short)(y2), 15);
        break;
        //---------------------------------- sample 4 ---------------------------------
    case 4:
        countAdcInt++;

        y1_part5 = FIR_filter_sc(H_Delay1_DEC,
        b_FIR_dec_Poly1, N_DEC_DELAYS, inL, 15);
        //delay1 = inL;

        y3 = FIR_filter_sc(H_Delay4_INT,
                b_FIR_dec_Poly4, N_DEC_DELAYS, (short)(y2), 15);

        break;
    default:
        break;

    }

    //g_i16Data[0] = (short)(y2)* MM;
    g_i16Data[0] = (short)(y3)* MM;

    // ---------------------------------------------------------------------------------------------------------




    // ---------------------------------------------------------------------------------------------------------
    // Assignment 4.3

    for( i = K_DELAYS;i>0;i--){
        allpass_buf[i] = allpass_buf[i-1];
    }
    allpass_buf[0] = inL;

    g_i16Data[1] = (short)(allpass_buf[K_DELAYS-1]-(short)(y3)*MM);

    // ---------------------------------------------------------------------------------------------------------

    // Put your ADC DSP code here ...s
    // create polyphase signals, low sampling rate
    /*
        switch (lambda) {
        case 0:
            g_PolyW[0] = g_i16AdcData[ADC0];
            g_PolyWUpdate = 0;
            break;
*/

}

/*******************************************************************//**
  @brief    PRU interrupt for DAC
  @param    -
  @return   -
 ***********************************************************************/
__interrupt void dacInt (void)
{

    // Put your DAC DSP code here ...



    // write DAC channels
    PRU_addaRegs->dac[0] = g_i16Data[0];
    PRU_addaRegs->dac[1] = g_i16Data[1];
}

/*******************************************************************//**
  main program
 ***********************************************************************/
void main (void)
{
    // Put your variables to be initialized in main() here ...

    /*******************************************************************
	  locals
     *******************************************************************/
    //    CSL_GpioRegsOvly GpioRegs = (CSL_GpioRegsOvly)CSL_GPIO_0_REGS;
    int32_t retval;

    /*******************************************************************
	  Board Initialization,
	  required only for CCS debugging to put board into a defined state
     *******************************************************************/
    UNIDAQ2_init (SDRAM_NOINIT | PLL_NOINIT);

    /*******************************************************************
	  print startup message
     *******************************************************************/
    System_puts ("\r\n-------------------------------------------------\r\n"
            "        #######:        UniDAQ2.DSP-ADDA\r\n"
            "        ###'\r\n"
            " .####: ###               PRU ADDA Demo\r\n"
            " ###    ###\r\n"
            " '########'  D.SignT GmbH & Co.KG  www.dsignt.de\r\n"
            "-------------------------------------------------\r\n\n");
    printf("ADC_FSAMP : %15.6f Hz, DAC_FSAMP : %15.6f Hz\n", (float) ADC_FSAMP, (float) DAC_FSAMP);

    /*******************************************************************
      I2C Initialization
     *******************************************************************/
    retval = I2C_init (400000, 0x7E);
    if (retval != ERROR_NONE)
    {
        System_puts("I2C_init() failed! program halted\r\n");
        for (;;);  /* trap or error handling */
    }

    /*******************************************************************
      Interrupt System Initialization
     *******************************************************************/
    INT_init (&INT_vectorTable);
    INT_sel (15, INT_EVT_IIC1_INT);
    INT_instFunc (15, I2C_int);
    INT_sel (4, INT_EVT_PRUEVT6);
    INT_instFunc (4, adcInt);
    INT_sel (5, INT_EVT_PRUEVT7);
    INT_instFunc (5, dacInt);
    INT_start();

    /*******************************************************************
      ADC Initialization:
        +/-10V range
        no oversampling
        sampling clock generated by Timer A, 100kHz
     *******************************************************************/
    retval = ADC_config(RANGE_10, OS_NONE, ADCTRIG_TIMERA, ADC_FSAMP);  // Svg
    if (retval != ERROR_NONE)
    {
        System_puts("ACD_config() failed! program halted\r\n");
        for (;;);  /* trap or error handling */
    }

    /*******************************************************************
	  DAC Initialization:
	    +/-10V range
	    synchronized to ADC
	    no calibration
	    no monitor output
     *******************************************************************/
    retval = DAC_config(DAC_CFGREG_GAIN4, DACTRIG_TIMERB, DAC_FSAMP, NULL, NULL, REF5V, MON_OFF);

    if (retval != ERROR_NONE)
    {
        System_puts("DAC_config() failed! program halted\r\n");
        for (;;);  /* trap or error handling */
    }

    /*******************************************************************
	  enable PRU, load and execute PRU code
     *******************************************************************/
    PRU_init();
    PRU_load(PRU_NUM, (void *)PRU_addaCode, sizeof(PRU_addaCode));
    if (PRU_run(PRU_NUM) != ERROR_NONE)
    {
        System_puts("PRU_run() failed! program halted\r\n");
        for (;;);  /* trap or error handling */
    }

    /*******************************************************************
      start data acquisition
     *******************************************************************/
    System_puts("signal processing started, loopback ADC 1..8 -> DAC 1..8\r\n");
    DAC_start();
    ADC_start();

    /*******************************************************************
	  main program loop
     *******************************************************************/
    for (;;)
    {
        // infinite for loop
    } // for (;;)...
}
