; Archivo: tmr1_tmr2
; Dispositivo: PIC16F887
; Autor: Nicolas Urioste
; Compilador: pic.as (v2.31) MPLAB v5.50
;
; Programa: uso del tmr1 para incrementar una variable
    
; Hardware: leds para ver que la variable si esta ciendo incrementada
;    
; Creado 29/08/2021
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
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

PSECT resVect, class=CODE, abs, delta=2
;-------------------------------------------------------------------------------
; Macros
;-------------------------------------------------------------------------------    
restart_tmr1 macro  ;50ms
    movlw   0x3C
    movwf   TMR1H   ;preload high
    movlw   0xB0
    movwf   TMR1L   ;preload low, 0x3CB0=15536
    bcf	    TMR1IF  ;limpiar la bandera
    endm

;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_bank0
    ;contador de ciclos tmr0
    cont:
	DS 2
	
    conteo_1:
	DS 2
    
PSECT udata_shr
    ;interrupciones
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
PSECT intVect, class=code, delta=2, abs
ORG 0x0004
push:
    movwf   W_TEMP
    swapf   STATUS, W
    movwf   STATUS_TEMP
    
isr: ;codigo de interrupcion
    btfsc   TMR1IF
    call    int_tmr1
    
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
    
;-------------------------------------------------------------------------------
; Subrutinas de interupcion
;-------------------------------------------------------------------------------
int_tmr1:   ;reloj de 1 segund
    restart_tmr1
    incf    cont
    movf    cont, W
    sublw   5		;cuantas veces se debe repetir
    btfss   STATUS, 2    ;si la resta es 0 se hace 0
    goto    return_tmr1
    clrf    cont  
    incf    PORTA
    return
    
return_tmr1:
    return
    
;-------------------------------------------------------------------------------
; Configuracion
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 0x0040
 
main:
    call config_io	;PORTA salida 
    call config_clock	;8MHz
    call config_ie	;activar interrupciones
    call config_tmr1	;1:4	preload 
    banksel PORTA
    
;-------------------------------------------------------------------------------
; LOOP principal
;-------------------------------------------------------------------------------
loop:
    goto    loop	;loop sin fin
    
;-------------------------------------------------------------------------------
; Rutinas de configuracion
;-------------------------------------------------------------------------------
config_io:
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH
    
    banksel TRISA   ;banco 1
    clrf    TRISA   ;contador boton en PORTA
    clrf    TRISB   
    clrf    TRISC
    
    banksel PORTA   ;banco 0
    clrf    PORTA
    clrf    PORTB
    clrf    PORTC
return    
    
config_clock:
    banksel OSCCON
    bsf	    IRCF2   ;1
    bsf	    IRCF1   ;1
    bcf	    IRCF0   ;0	    oscilador a 4MHz
    bsf	    SCS	    ;se utiliza el oscilador como el reloj interno
return
    
config_ie:
    banksel TRISA
    bsf	    TMR1IE  ;interrupcion tmr1
    
    banksel PORTA
    bcf	    TMR1IF  ;bandera tmr1
    
    bsf	    PEIE    ;interrupciones perifericas
    bsf	    GIE	    ;interrupciones globales
    return
    
config_tmr1:
    banksel PORTA
    bcf	    TMR1GE  ;always active
    bcf	    T1CKPS1 ;0
    bsf	    T1CKPS0 ;1, 01, escala 1:2
    bcf	    T1OSCEN ;LP oscilador apagado
    bcf	    TMR1CS  ;Usa el oscilador interno de PIC
    bsf	    TMR1ON  ;prender el tmr1
    restart_tmr1
    return
