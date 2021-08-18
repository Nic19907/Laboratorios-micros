; Archivo: lab3-datch.2
; Dispositivo: PIC16F887
; Autor: Nicolas Urioste
; Compilador: pic.as (v2.31) MPLAB v5.50
;
; Programa: Contador binario de 4 bits que incrementa con 2 pushbuttons
    ; los p.b. hacen uso de las interrupciones on-change del PORTB
    
; Hardware: push buttons y 4 leds
;    
; Creado 11/08/2021
; Modificado: xx/08/2021   
    
; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

PROCESSOR 16F887
#include <xc.inc>


;-------------------------------------------------------------------------------
; Palabras de configuracion
;-------------------------------------------------------------------------------
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

PSECT resVect, class=CODE, abs, delta=2
;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_shr
 
;-------------------------------------------------------------------------------
; Vector Reset
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 0x0000
resVect:
    goto main

;-------------------------------------------------------------------------------
; Configuracion
;-------------------------------------------------------------------------------
PSECT loopPrincipal, class=code, delta=2, abs
ORG 0x000A
 
main:
    call config_io
    call config_clock
    call config_tmr0
    banksel PORTA
    
;-------------------------------------------------------------------------------
; LOOP principal
;-------------------------------------------------------------------------------
loop:
    call    clock_1s
    call    config_contador
    goto    loop
;-------------------------------------------------------------------------------
; Rutinas de configuracion
;-------------------------------------------------------------------------------
config_io:
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH
    
    banksel TRISA   ;banco 1
    clrf    TRISA   ;contador 100ms
    clrf    TRISB   ;contador 1s
    clrf    TRISC   ;7 segmentos
    clrf    PORTE   ;LED indicadora de ciclo
    
    bsf	    TRISD,0
    bsf	    TRISD,1 ;entradas de los botones
    
    banksel PORTA   ;banco 0
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
    clrf    PORTE
return
    
config_clock:
    banksel OSCCON
    bsf	    OSCCON, 6   ;1
    bcf	    OSCCON, 5	;0
    bcf	    OSCCON, 4   ;0	    oscilador a 1MHz
    bsf	    OSCCON, 0	    ;se utiliza el oscilador como el reloj interno
return
    
;-------------------------------------------------------------------------------
; Subrutinas
;-------------------------------------------------------------------------------