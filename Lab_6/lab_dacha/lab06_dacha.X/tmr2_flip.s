; Archivo: tmr2_flip.s
; Dispositivo: PIC16F887
; Autor: Nicolas Urioste
; Compilador: pic.as (v2.31) MPLAB v5.50
;
; Programa: uso del tmr2 para cambiar el estado de un led
    
; Hardware: leds para ver que cambia de estado
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
    btfsc   TMR2IF
    call    int_tmr2
    
pop:
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
    
;-------------------------------------------------------------------------------
; Subrutinas de interupcion
;-------------------------------------------------------------------------------
int_tmr2:
    bcf	    TMR2IF
    incf    cont
    movf    cont, W
    sublw   10		;cuantas veces se debe repetir
    btfss   STATUS, 2    ;si la resta es 0 se hace 0
    goto    brake
    clrf    cont
    incf    conteo_1
    return
    
brake:
    return

;-------------------------------------------------------------------------------
; Configuracion
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 0x0040 
 main:
    call	config_io
    call	config_clock
    call	config_tmr2
    call	config_ie
    banksel	PORTA
    
;-------------------------------------------------------------------------------
; LOOP principal
;-------------------------------------------------------------------------------
 loop:
    movf	conteo_1, w	    // pasar variable incrementada a puerto b
    movwf	PORTB		    // para poder visualizar sus cambios
    goto	loop
 
;-------------------------------------------------------------------------------
; Rutinas de configuracion
;-------------------------------------------------------------------------------
config_io:		    ; entradas y salidas
    banksel	ANSEL
    clrf	ANSEL
    clrf	ANSELH	    ; pines digitales
    banksel	TRISA
    bcf		TRISB,0	    ; puerto a como salida
    banksel	PORTA
    bcf		PORTB,0	    ; limpiar puerto a
    return

config_clock:
    banksel OSCCON
    bsf	    IRCF2   ;1
    bsf	    IRCF1   ;1
    bcf	    IRCF0   ;0	    oscilador a 4MHz
    bsf	    SCS	    ;se utiliza el oscilador como el reloj interno
return

config_tmr2: ;se le pone el valor al que el contador debe llegar
    banksel PORTA
    bsf	    TOUTPS3 ;1
    bsf	    TOUTPS2 ;1
    bsf	    TOUTPS1 ;1
    bsf	    TOUTPS0 ;1,	1111 Postscaler 1:16

    bsf	    T2CKPS1 ;1
    bsf	    T2CKPS0 ;1,	11 prescaler 1:16
    
    bsf	    TMR2ON  ;encender el tmr2   
    ;0.04992 ~= 0.05
    banksel TRISA
    movlw   195
    movwf   PR2
    clrf    TMR2
    bcf	    TMR2IF
    return

config_ie:
    banksel TRISA
    bsf	    TMR2IE  ;interrupcion tmr2
    
    banksel PORTA
    bsf	    GIE	    ;interrupciones globales
    bsf	    PEIE    ;interrupciones perifericas
    bcf	    TMR2IF  ;bandera tmr2
    return