; Archivo: lab5_post
; Dispositivo: PIC16F887
; Autor: Nicolas Urioste
; Compilador: pic.as (v2.31) MPLAB v5.50
;
; Programa: Contador binario de 8 bits que incrementa con 1 boton y decrementa 
	    ;con el otro, El contador va a ser reflejado en dos display de 7
	    ;conectados al mismo puerto y en hexadecimal, hacer uso del tmr0
	    ;para lograr ensenar ambos display en un puerto
	    ;el contador tambien estara en otro puerto y saldra en decimal con
	    ;3 display de 7 segmentos
    
; Hardware: 2 push bottons, 5 display de 7 segmentos, 3 o 5 transistores y
	    ; resistencias varias
;    
; Creado 24/08/2021
; Modificado: 25/08/2021   
    
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
    movlw   117     ;preload
    movwf   TMR0    ;ciclo de .052 ms
    bcf	    T0IF
    endm
  
wdivl	macro	divisor, cociente, residuo
    movwf   conteo
    clrf    conteo+1
    
    incf    conteo+1
    movlw   divisor
    
    subwf   conteo, F
    btfsc   STATUS,0
    goto    $-4
    
    decf    conteo+1, w
    movwf   cociente
    
    movlw   divisor
    addwf   conteo, w
    movwf   residuo	;divicion en 100
    endm

;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_shr
;variables para delay
time_1:
    DS 1
time_2:
    DS 1
 
;interrupciones
W_TEMP:
    DS  1
STATUS_TEMP:    
    DS  1

PSECT udata_bank0
bit8:
    DS 1
conteo:   ;cuenta cuantas veces se a orecionado
    DS 2
	
cos_dec:    ;cociente de la divicion
    DS 1
    
res_dec:    ;residuo de la divicion
    DS 2
    
redivisor:  ;util para obtener las decenas
    DS 1

resultado_div:	;resultado de la divicion
    DS 3
    
display_7dec:	;valor post tabla
    DS 3
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
;transistor 0, centenas
    ;trnasistor 1, decenas
	;transsitor 2, unidades

int_tmr0:
    restart_tmr0	;reinicia tmr0
    goto test_unidades	;logica para ir cambiando transistores cada ciclo
    
test_unidades:
    btfss   PORTD, 2	  ;esta encendido el transistor 2, unidades?
    goto    test_decenas  ;apagado
    goto    display_0	  ;encendido

test_decenas:
    btfss   PORTD, 1	    ;esta encendido el transistor 1, decenas?
    goto    display_1	    ;apagado
    goto    display_2	    ;encendido
    
display_0:  ;centenas
    clrf    PORTD   ;apaga todos los rtansistores
    movf    display_7dec,w
    movwf   PORTB   ;poner en el PORTB las centenas
    movlw   001B    ;asigna 001B a w
    movwf   PORTD   ;enciende transistor 0
    goto    brake   ;sale de la int
    
display_1:  ;decenas
    clrf    PORTD   ;apaga todos los transistores
    movf    display_7dec+1,w
    movwf   PORTB   ;poner en PORTB las decenas
    movlw   010B    ;asignar 010B a w
    movwf   PORTD   ;enciende el transistor 1
    goto    brake   ;sale de la int

display_2:  ;unidades
    clrf    PORTD   ;apaga todos los transistores
    movf    display_7dec+2,w
    movwf   PORTB   ;poner en PORTB las unidades
    movlw   100B    ;asignar 100B a w
    movwf   PORTD   ;enciende el transistor 2
    
brake:
    return  ;termina la interrupcion

    
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
    call config_clock	;1MHz
    call config_tmr0
    call config_ie
    banksel PORTA
    
;-------------------------------------------------------------------------------
; LOOP principal
;-------------------------------------------------------------------------------
loop:
    call    contador_8bits 
    call    div_100	;obtener centenas
    call    div_10	;decimales y unidades
    call    preparar_display	;divicion completa y cada uno opti. para display
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
    clrf    TRISB   ;contador centenas
    clrf    TRISC   ;contador decenas
    bcf	    TRISD,0   ;contador unidades
    bcf	    TRISD,1   ;contador unidades
    bcf	    TRISD,2
    ;bcf	    TRISD,2   ;contador unidades

    banksel PORTA   ;banco 0
    clrf    PORTA 
    clrf    PORTB
    clrf    PORTC
    bcf	    PORTD,0
    bcf	    PORTD,1
    bcf	    PORTD,2
return
    
config_clock:
    banksel OSCCON
    bsf	    IRCF2   ;1
    bsf	    IRCF1   ;1
    bcf	    IRCF0   ;0	    oscilador a 4MHz
    bsf	    SCS	    ;se utiliza el oscilador como el reloj interno
return
    
config_tmr0: //configurar el timer0 a 10ms
    banksel OPTION_REG
    bcf	    T0CS    ;reloj interno
    bcf	    PSA	    ;prescaler asignado al TMR0
    bsf	    PS2	    ;1
    bcf	    PS1	    ;0
    bcf	    PS0	    ;0  100, escala de 1:32
    return
    
config_ie:
    bsf	    GIE	    ;interrupciones activadas
    bsf	    T0IE 
    bsf	    T0IF    ;banderas del tmr0
    return

;-------------------------------------------------------------------------------
; Subrutina contador con leds
;-------------------------------------------------------------------------------
contador_8bits:
    btfsc   RE0	    ;Push button en Pull DOWN
    call    inc_A   
    btfsc   RE1	    ;lo mismo que RD0
    call    dec_A
    
    movf    bit8, W
    movwf   PORTA
    return
    
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
    incf    bit8	    ;incrementar el conteo de PORTC
return

dec_A:
    call    delay_500us	    ;esta para evitar un rebote
    btfsc   RE1		    ;(el boton esta ciendo precionado) hasta que no se
			    ;suelte el boton no saltara el goto
    goto    $-1
    decf    bit8	    ;incrementar el conteo de PORTC
return
    
;-------------------------------------------------------------------------------
; Subrutina 7 segmentos decimal
;-------------------------------------------------------------------------------
preparar_display:
    movf    resultado_div, w
    call    tabla_7seg
    movwf   display_7dec    ;centena
    
    movf    resultado_div+1, w
    call    tabla_7seg
    movwf   display_7dec+1  ;decena
    
    movf    resultado_div+2, w
    call    tabla_7seg
    movwf   display_7dec+2  ;unidad
    return

div_100:
    movf    PORTA, W
    wdivl   100, cos_dec, res_dec	;dividir conteo en 100
    movf    cos_dec, w
    movwf   resultado_div
    movf    res_dec, w
    movwf   redivisor
    return

div_10:
    movf    redivisor, w
    wdivl   10, cos_dec+1, res_dec+1
    movf    cos_dec+1, w
    movwf   resultado_div+1
    movf    res_dec+1, w
    movwf   resultado_div+2
    return
    
    
END


