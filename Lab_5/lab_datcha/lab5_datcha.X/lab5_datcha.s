; Archivo: lab5_datcha
; Dispositivo: PIC16F887
; Autor: Nicolas Urioste
; Compilador: pic.as (v2.31) MPLAB v5.50
;
; Programa: Contador binario de 8 bits que incrementa con 1 boton y decrementa 
	    ;con el otro, El contador va a ser reflejado en dos display de 7
	    ;conectados al mismo puerto y en hexadecimal, hacer uso del tmr0
	    ;para lograr ensenar ambos display en un puerto
    
; Hardware: 2 push bottons, 2 display de 7 segmentos, 2 transistores y
	    ; resistencias varias
;    
; Creado 20/08/2021
; Modificado: 20/08/2021   
    
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
    movlw   176	    ;prescaler
    movwf   TMR0    ;ciclo de .09 ms
    bcf	    T0IF
    endm
    
;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_shr
time_1:	    ;util para dilay
    DS 1 ;Variable con 2 localidades en RAM
    
time_big:
    DS 1

W_TEMP:
    DS  1
STATUS_TEMP:    
    DS  1
    
PSECT udata_bank0
var: ;var=contador	
    DS 1
    
banderas:
    DS 1

nibble:
    DS 2
    
display_var:
    DS 2
/*
banderas:
    DS 1
contador:   ;variable para contador 8 bits, util para el 7 segmentos
    DS 1
cont:	    ;cuantas veces se ha levantado la vandera del tmr0
    DS 1
ciclos:   ;cuantos ciclos ha completado las 100 repeticiones de la intrupcion
    DS 1
    
hex7:	;representacion post divicion para el reloj hexadecimal
    DS 2    ;0 para unidades y +1 para decenas
    
nibble:	;para la separacion de nibbles
    DS 2
display_hex7:
    DS 2
 spoilers
dec7:	;representacion post divicion para el reloj decimal
    DS 3    ;0 para unidades, +1 para decenas y +2 centenas
*/
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
    ;se decidio usar delays en lugar de banderas con los botones
    btfsc   T0IF	;ver si la bandera del tmr0 esta prendida	
    call    int_tmr0	;contador de 1s
    
    
pop:
    swapf   STATUS_TEMP ;W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie
    
;-------------------------------------------------------------------------------
; Subrutinas de interupcion
;-------------------------------------------------------------------------------
int_tmr0:;el tmr0 sirve para controlar el tiempo por display
    restart_tmr0 ;
    clrf    PORTD
    btfsc   banderas, 0
    goto    display_1
    
display_0:
    movf    display_var, W
    movwf   PORTB
    bsf	    PORTD,0
    goto    siguiente_display
    
display_1:
    movf    display_var+1, W
    movwf   PORTB
    bsf	    PORTD,1
    
siguiente_display:
    movlw   1
    xorwf   banderas, F
    return
        
;-------------------------------------------------------------------------------
; TABLAS
;-------------------------------------------------------------------------------
ORG 0x0100
tabla_7seg:
    clrf    PCLATH
    bsf	    PCLATH, 0 ;PCLATH = 101, PCL=02
    andlw   0x0f    ; solo contara los primeros 4 bits
    addwf   PCL	    ; PC = PCLATH + PCL + W
    retlw   00111111B	;0
    retlw   00000110B	;1
    retlw   01011011B	;2
    retlw   01001111B	;3
    retlw   01100110B	;4
    retlw   01101101B	;5
    retlw   01111101B	;6
    retlw   00000111B	;7
    retlw   01111111B	;8
    retlw   01100111B	;9
    retlw   01110111B	;A
    retlw   01111100B	;b
    retlw   00111001B	;C
    retlw   01011110B	;d
    retlw   01111001B	;E
    retlw   01110001B	;F
    
;-------------------------------------------------------------------------------
; Configuracion
;-------------------------------------------------------------------------------
PSECT code, delta=2, abs
ORG 0x0040
 
main:
    call config_io	;PORTA salida ; RB0 y RB1 inputs
    call config_clock	;8MHz
    call config_tmr0_ie
    banksel PORTA
    
;-------------------------------------------------------------------------------
; LOOP principal
;-------------------------------------------------------------------------------
loop:
    call    contador_8bits
    call    separa_nible
    call    preparar_display
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
    clrf    TRISB   ;contador hexadecimal en PORTB
    ;clrf    TRISC   ;contador decima en PORTC
    bcf	    TRISD,0
    bcf	    TRISD,1
    ;spoilers clrf    TRISD   ;controlador de transistores en PORTC

    banksel PORTA   ;banco 0
    clrf    PORTA   
    clrf    PORTB   
    clrf    PORTC   
    ; spoilers clrf    PORTD   
    ;clrf    PORTE  ;eliminar todo al inicio 
return
    
config_clock:
    banksel OSCCON
    bsf	    IRCF2   ;1	;1MHz
    bsf	    IRCF1   ;1
    bsf	    IRCF0   ;1	    oscilador a 8MHz
    bsf	    SCS	    ;se utiliza el oscilador como el reloj interno
return
    
config_tmr0_ie: //configurar el timer0 a 10ms
    banksel OPTION_REG
    bcf	    T0CS    ;reloj interno
    bcf	    PSA	    ;prescaler asignado al TMR0
    bsf	    PS2	    ;0
    bsf	    PS1	    ;0
    bsf	    PS0	    ;0  000, escala de 1:2
    banksel PORTA
    restart_tmr0
    bsf	    GIE	    ;interrupciones activadas
    bsf	    T0IE
    bcf	    T0IF    ;banderas del tmr0
    return  

;-------------------------------------------------------------------------------
; Subrutina contador con leds
;-------------------------------------------------------------------------------
contador_8bits:
    btfsc   RE0	    ;Push button en Pull DOWN
    call    inc_A   
    btfsc   RE1	    ;lo mismo que RD0
    call    dec_A
    
    movf    var, W
    movwf   PORTA
    return

delay_500us:
    movlw   250	;valor inicial contador 
    movwf   time_1
    decfsz  time_1, 1	;decrementar por 1 el contador 
    goto    $-1		;ejecutar linea anterior
return
    
delay_big:
    movlw   200		    ;valor inicial del contador
    movwf   time_big	    
    call    delay_500us	    ;realizar el delay_small 
    decfsz  time_big, 1	    ;decrementar por 1 el contador
    goto    $-2		    ;ejecutar dos lineas atras
    return

inc_A:
    call    delay_big	    ;esta para evitar un rebote
    btfsc   RE0		    ;(el boton esta ciendo precionado) hasta que no se
			    ;suelte el boton no saltara el goto
    goto    $-1
    incf    var	    ;incrementar el conteo de PORTC
return

dec_A:
    call    delay_big	    ;esta para evitar un rebote
    btfsc   RE1		    ;(el boton esta ciendo precionado) hasta que no se
			    ;suelte el boton no saltara el goto
    goto    $-1
    decf    var	    ;incrementar el conteo de PORTC
return

;-------------------------------------------------------------------------------
; Subrutina contador con 7 segmentos hexadecimal
;-------------------------------------------------------------------------------
    ;var=contador
separa_nible:
    movf    var, w
    andlw   0x0f
    movwf   nibble
    swapf   var, w
    andlw   0x0f
    movwf   nibble+1
    return
    
preparar_display:
    movf    nibble, W
    call    tabla_7seg
    movwf   display_var
    movf    nibble+1, W
    call    tabla_7seg
    movwf   display_var+1
    return
END