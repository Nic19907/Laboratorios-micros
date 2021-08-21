; Archivo: lab5_pre
; Dispositivo: PIC16F887
; Autor: Nicolas Urioste
; Compilador: pic.as (v2.31) MPLAB v5.50
;
; Programa: Contador binario de 4 bits que incrementa con 2 pushbuttons
    ; los p.b. hacen uso de las interrupciones on-change del PORTB
    ;contador de 1000ms en el PORTC
    ;contador de segundos y decasegundo con el display 7 segmentos
    
; Hardware: push buttons y 4 leds y otros 4leds, dos 7segmentos de catodo
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

;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_shr
  ;contador de 8 bits
time_1:
    DS 1 ;Variable con 2 localidades en RAM
time_2:
    DS 1

PSECT udata_bank0
contador:
    DS 1
	
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
PSECT code, delta=2, abs
ORG 0x0040
 
main:
    call config_io	;PORTA salida ; RB0 y RB1 inputs
    call config_clock	;1MHz
    banksel PORTA
    
;-------------------------------------------------------------------------------
; LOOP principal
;-------------------------------------------------------------------------------
loop:
    call    contador_8bits
    goto    loop	;loop sin fin
    
;-------------------------------------------------------------------------------
; Rutinas de configuracion
;-------------------------------------------------------------------------------
config_io:
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH
    
    banksel TRISA   ;banco 1
    clrf    TRISA   ;contador botones en PORTA

    banksel PORTA   ;banco 0
    clrf    PORTA   
    ;clrf    PORTE  ;eliminar todo al inicio 
return
    
config_clock:
    banksel OSCCON
    bsf	    IRCF2   ;1
    bsf	    IRCF1   ;0
    bcf	    IRCF0   ;0	    oscilador a 1MHz
    bsf	    SCS	    ;se utiliza el oscilador como el reloj interno
return

;-------------------------------------------------------------------------------
; Subrutinas
;-------------------------------------------------------------------------------
delay_500us:
    movlw   250	;valor inicial contador 
    movwf   time_1
    decfsz  time_1, 1	;decrementar por 1 el contador 
    goto    $-1		;ejecutar linea anterior
return

delay_200ms:
    movlw   200
    movwf   time_2
    call    delay_500us
    decfsz  time_2,1
    goto    $-2
    return

inc_A:
    call    delay_500us	    ;esta para evitar un rebote
    btfsc   RE0		    ;(el boton esta ciendo precionado) hasta que no se
			    ;suelte el boton no saltara el goto
    goto    $-1
    incf    contador	    ;incrementar el conteo de PORTC
return

dec_A:
    call    delay_500us	    ;esta para evitar un rebote
    btfsc   RE1		    ;(el boton esta ciendo precionado) hasta que no se
			    ;suelte el boton no saltara el goto
    goto    $-1
    decf    contador	    ;incrementar el conteo de PORTC
return

contador_8bits:
    btfsc   RE0	    ;Push button en Pull DOWN
    call    inc_A   
    btfsc   RE1	    ;lo mismo que RD0
    call    dec_A
    
    movf    contador, W
    movwf   PORTA
    return
    
END