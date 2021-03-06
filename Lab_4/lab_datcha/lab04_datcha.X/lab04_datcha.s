; Archivo: lab3-datch.2
; Dispositivo: PIC16F887
; Autor: Nicolas Urioste
; Compilador: pic.as (v2.31) MPLAB v5.50
;
; Programa: Contador binario de 4 bits que incrementa con 2 pushbuttons
    ; los p.b. hacen uso de las interrupciones on-change del PORTB
    ;contador de 1000ms en el PORTC
    
; Hardware: push buttons y 4 leds y otros 4leds
;    
; Creado 16/08/2021
; Modificado: 16/08/2021   
    
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
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

PSECT resVect, class=CODE, abs, delta=2
;-------------------------------------------------------------------------------
; Macros
;-------------------------------------------------------------------------------
restart_tmr0 macro
    banksel PORTA
    movlw   99	    ;prescaler
    movwf   TMR0    ;ciclo de 10 ms
    bcf	    T0IF
    endm
;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------

UP	EQU 0
DOWN	EQU 7
	
PSECT udata_bank0
    cont:   
	DS 2
PSECT udata_shr
    W_TEMP:
	DS  1
    STATUS_TEMP:    
	DS  1
 
;-------------------------------------------------------------------------------
; Vector Reset
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 0x0000
resVect:
    goto main

;-------------------------------------------------------------------------------
; Vector de interrupcion
;-------------------------------------------------------------------------------
ORG 0x0004
push:
    movwf   W_TEMP
    swapf   STATUS, W
    movwf   STATUS_TEMP
    
isr: ;codigo de interrupcion
    btfsc   RBIF
    call    int_iocb	;contador de botones
    btfsc   T0IF
    call    int_tmr0
    
    
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
    
;-------------------------------------------------------------------------------
; Subrutinas de interupcion
;-------------------------------------------------------------------------------
int_iocb:
    banksel PORTB
    btfss   PORTB, UP
    incf    PORTA
    call    lim_maxA
    btfss   PORTB, DOWN
    decf    PORTA
    call    lim_minA
    bcf	    RBIF
    return
    
int_tmr0:
    restart_tmr0 ;10ms
    incf    cont
    movf    cont, W
    sublw   100		;cuantas veces se debe repetir
    btfss   STATUS, 2    ;si la resta es 0 se hace 0
    goto    return_tmr0
    clrf    cont    ;1000ms
    incf    PORTC
    call    lim_tmr0
    return
    
return_tmr0:
    return
;-------------------------------------------------------------------------------
; Configuracion
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 0x0040
 
main:
    call config_io	;PORTA salida ; RB0 y RB1 inputs
    call config_clock	;4MHz
    call config_iocrb
    call config_int_enable
    call config_tmr0
    banksel PORTA
    
;-------------------------------------------------------------------------------
; LOOP principal
;-------------------------------------------------------------------------------
loop:
    goto    loop
;-------------------------------------------------------------------------------
; Rutinas de configuracion
;-------------------------------------------------------------------------------
config_io:
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH
    
    banksel TRISA   ;banco 1
    clrf    TRISA   ;contador boton en PORTA
    clrf    TRISC   ;contador de 1000ms
    
    bsf	    TRISB, UP
    bsf	    TRISB, DOWN	;botones de entrada
    bcf	    OPTION_REG, 7   ;habilitar pull-ups
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    
    banksel PORTA   ;banco 0
    clrf    PORTA
    clrf    PORTC
return
    
config_clock:
    banksel OSCCON
    bsf	    IRCF2   ;1
    bsf	    IRCF1   ;0
    bcf	    IRCF0   ;0	    oscilador a 1MHz
    bsf	    SCS	    ;se utiliza el oscilador como el reloj interno
return

config_iocrb:
    banksel TRISA
    bsf	    IOCB, UP
    bsf	    IOCB, DOWN
    
    banksel PORTA
    movf    PORTB, w	;al leer terminar condicion de mismatch
    bcf	    RBIF
    return
    
config_int_enable:
    bsf	    GIE	    ;interrupciones activadas
    bsf	    RBIE    ;PORTB pueden cambiar interrupciones
    bcf	    RBIF
    
    ;banderas del tmr0
    bsf	    T0IE
    bcf	    T0IF
    return
    
config_tmr0: //configurar el timer0 a 10ms
    banksel OPTION_REG
    bcf	    T0CS    ;reloj interno
    bcf	    PSA	    ;prescaler asignado al TMR0
    bsf	    PS2	    ;1
    bcf	    PS1	    ;0
    bsf	    PS0	    ;1  101, escala de 1:32
    return    
    
;-------------------------------------------------------------------------------
; Subrutinas
;-------------------------------------------------------------------------------
lim_maxA:
    btfsc   PORTA,4
    clrf    PORTA
    return
    
lim_minA:
    btfsc   PORTA,7
    call    del_A
    return

del_A:
    bcf	    PORTA,7
    bcf	    PORTA,6
    bcf	    PORTA,5
    bcf	    PORTA,4
    return

lim_tmr0:
    btfsc   PORTC,4
    clrf    PORTC
    return
     /*    
restart_tmr0:
    banksel PORTA
    movlw   99	    ;prescaler
    movwf   TMR0    ;ciclo de 10 ms
    bcf	    T0IF
    return
*/
     /*
           ,::////;::-.
      /:'///// ``::>/|/
    .',  ||||    `/( e\
-==~-'`-Xm````-mm-' `-_\ 
    */
    
END