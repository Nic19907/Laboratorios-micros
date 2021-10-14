/*
 * File: 3potes.c
 * Dispositivo:     PIC16F887
 * Compilador:  pic.as (v2.31) MPLAB (5.50)
 * 
 * Programa: Toma una sennal analogica y con el pwm hace que se mueva un servo
 * tambien se hace un pwm "manual" para afectar un led
 * Hardware: Potenciometro, servo, resistencias
 * 
 * Creado: 10/10/2021
 * Modificado: XX/10/2021
 * 
 * Author: Nicolas Urioste
 *
 * Created on 10 de octubre de 2021, 10:04 AM
 */

#include <xc.h>
#include <stdint.h>

#define _XTAL_FREQ 8000000
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

/*
--------------------------------------------------------------------------------
 *                              Variables
--------------------------------------------------------------------------------
 */
uint8_t ciclo;
uint8_t patata;

uint8_t load_tmr0;

/*
--------------------------------------------------------------------------------
 *                       Prototipo de funciones
--------------------------------------------------------------------------------
 */
void setup          (void);
void config_io      (void);
void config_clock   (void);
void config_ie      (void);
void config_ADC     (void);
void config_PWM     (void);
void config_tmr0    (void);

void setup (void){
    config_io();
    config_clock();
    config_ie();
    config_tmr0();
    config_ADC ();
    config_PWM ();
    return;
}
/*
--------------------------------------------------------------------------------
 *                              Interrupcion
--------------------------------------------------------------------------------
 */
void __interrupt() isr (void){
    if (PIR1bits.ADIF){
        if (ADCON0bits.CHS == 6){
            /* simulado
C           CCPR2L = (ADRESH>>1)+126;
            CCP2CONbits.DC2B0 = ADRESH & 0b01;
            CCP2CONbits.DC2B0 = (ADRESL>>7);             
             */
            
            //MG 996R
            CCPR2L = ADRESH ;
        }
        else if (ADCON0bits.CHS == 5){
            /* simulado
            CCPR1L = (ADRESH>>1)+126;
            CCP1CONbits.DC1B1 = ADRESH & 0b01;
            CCP1CONbits.DC1B0 = (ADRESL>>7);
             */
            
            //MG 996R
            CCPR1L = ADRESH;
        }
        else if (ADCON0bits.CHS == 7) {
            patata = ADRESH;
        }
        PIR1bits.ADIF = 0;
    }
    else {
        INTCONbits.T0IF = 0;
        TMR0 = load_tmr0;
        ciclo++;
    }
    return;
}

/*
--------------------------------------------------------------------------------
 *                                 Main/loop
--------------------------------------------------------------------------------
 */
void main(void) {
    setup();
    ADCON0bits.GO = 1;
    while (1){ //loop
        if (ADCON0bits.GO == 0){ //esta convirtiendo
            if (ADCON0bits.CHS == 6){
                ADCON0bits.CHS = 5;
            }
            else if (ADCON0bits.CHS == 5) {
                ADCON0bits.CHS = 7;
            }
            else {
                ADCON0bits.CHS = 6;
            }
            __delay_us(50);
            ADCON0bits.GO = 1;  //que convierta
        }
        
        if (ciclo <= patata){ //si los rep del tmr0 son menores al pote
            PORTDbits.RD0 = 1;
        }
        else if (ciclo > patata){
            PORTDbits.RD0 = 0;
            //if (ciclo >= periodo){
            //    ciclo = 0;
            //}
            
        }
        
        
    }
}

/*
--------------------------------------------------------------------------------
 *                              Configuracion
--------------------------------------------------------------------------------
 */
void config_io(void){
    ANSEL   = 0b11100000;  //RE0 y RE1 analogico
    ANSELH  = 0;
    
    TRISE   = 0b111;    //portE como entrada
    TRISD   = 0b0;      //RD0 como salida
    
    PORTD   = 0; //inicie en 0
    PORTE   = 0;
    
    load_tmr0 = 250;
    return;
}

void config_clock (void){
    OSCCONbits.IRCF = 0b0111; //8MHz
    OSCCONbits.SCS  = 1;     //usar el reloj interno
    return;
}

void config_tmr0(void){
    OPTION_REGbits.T0CS = 0;    // Reloj interno
    OPTION_REGbits.T0SE = 0;    // Flancos positivos
    OPTION_REGbits.PSA = 0;     // Prescaler a Timer0
    OPTION_REGbits.PS = 0b011;  // Prescaler (011 = 1:16)
    TMR0 = load_tmr0;                 // Preload para 2 ms  original en 6
    return;
}

void config_ie (void){
    PIR1bits.ADIF   = 0;
    PIE1bits.ADIE   = 1; 
    
    INTCONbits.GIE  = 1; //interrupciones globales
    INTCONbits.PEIE = 1; //interr. perifericas
    INTCONbits.T0IE = 1; //interr. tmr0 activada
    INTCONbits.T0IF = 0; //interr. del tmr0 empieza apagada
    return;
}

void config_ADC (void){
    ADCON1bits.ADFM = 0; //justificacion a la izquierda
    ADCON1bits.VCFG0 = 0;// Vref en VSS y VDD
    ADCON1bits.VCFG1 = 0;
    
    
    ADCON0bits.ADCS = 0b10; // FOSC/32
    ADCON0bits.ADON = 1;    //habilitar el ADC
    ADCON0bits.CHS  = 5;    //empezar por el AN5
    __delay_us(50);
    return;
}

void config_PWM (void){
    TRISCbits.TRISC2 = 1; // RC2/CCP1 como entrada
    TRISCbits.TRISC1 = 1; // RC1/CCP2
    PR2 = 249;  //configuracion del periodo
    
    //CCP1
    CCP1CONbits.P1M = 0;  // configurar el modo PWM
    CCP1CONbits.CCP1M = 0b1100; //P1C active high
    CCPR1L = 0x0f;  //duty cycle
    CCP1CONbits.DC1B = 0;
    
    //CCP2
    CCP2CONbits.CCP2M = 0b1100; //PIC  PWM
    CCPR2L = 0x0f;  //duty cycle
    CCP2CONbits.DC2B0 = 0;
    CCP2CONbits.DC2B1 = 0;
    
    //TMR2
    PIR1bits.TMR1IF = 0; //limpiar la bandera
    T2CONbits.T2CKPS = 0b11; //prescaler 1:16
    T2CONbits.TMR2ON = 1;
    while (PIR1bits.TMR2IF == 0);//esperar 1 ciclo del tmr2
    PIR1bits.TMR2IF = 0;
    
    //pins pwm
    TRISCbits.TRISC2 = 0; //salida del PWM
    TRISCbits.TRISC1 = 0; //salida en el
    return;
}