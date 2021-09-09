; Archivo: tmrX_display.s
; Dispositivo: PIC16F887
; Autor: Nicolas Urioste
; Compilador: pic.as (v2.31) MPLAB v5.50
;
; Programa: uso del tmr2 para cambiar el estado de un led, tmr1 como contador
    ; de segundos y tmr0 para cambiar display
    
; Hardware: leds para ver que cambia de estado y display 7 segmentos
;    
; Creado 07/09/2021
; Modificado: 08/08/2021   
    
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
    movlw   6	    ;preload
    movwf   TMR0    ;ciclo de 2 ms
    bcf	    T0IF
    endm
    
restart_tmr1 macro
    movlw   0xB
    movwf   TMR1H   ;preload high
    movlw   0x47
    movwf   TMR1L   ;preloaf low, 0x0B47
    bcf	    TMR1IF  ;limpiar la bandera
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
    movwf   cociente	;cociente de la divicion

    movlw   divisor
    addwf   conteo, w
    movwf   residuo	;residuo de la divicion
    endm
;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
PSECT udata_bank0
    ;contador de ciclos tmr0
    cont:   ;cuantas veces a terminado el tmrX dentro de un ciclo
	DS 3
	
    aux:
	DS 3
	
    conteo: ;variable de la divicion
	DS 2
	
    resultado_div:  ;resultado de la divicion
	DS 1
	
    redivisor:	;util si se desea dividir en cadena
	DS 1
	
    cos_dec:    ;cociente de la divicion
	DS 1
	
    res_dec:    ;residuo de la divicion
	DS 1    
	
    display_7dec:	;valor post tabla
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
    ;btfsc   T0IF
    ;call    int_tmr0
    btfsc   TMR1IF
    call    int_tmr1
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
int_tmr0:
    restart_tmr0
    return
    
int_tmr1:   ;reloj de 1 segund
    restart_tmr1
    incf    cont+1
    movf    cont+1, W
    sublw   5		;cuantas veces se debe repetir
    btfss   STATUS, 2    ;si la resta es 0 se hace 0
    goto    brake
    clrf    cont+1  
    incf    aux+1
    return

int_tmr2:
    bcf	    TMR2IF
    incf    cont+2
    movf    cont+2, W
    sublw   10		;cuantas veces se debe repetir
    btfss   STATUS, 2    ;si la resta es 0 se hace 0
    goto    brake
    clrf    cont+2
    incf    aux+2
    return
    
brake:
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
    call    config_io
    call    config_clock
    ;call    config_tmr0
    call    config_tmr1
    call    config_tmr2
    call    config_ie
    banksel	PORTA
    
;-------------------------------------------------------------------------------
; LOOP principal
;-------------------------------------------------------------------------------
 loop:
    call    intermitente
    call    div_10
    call    preparar_display7_dec
    movf    display_7dec, w
    movwf   PORTC
    goto    loop
    
;-------------------------------------------------------------------------------
; Rutinas de configuracion
;-------------------------------------------------------------------------------
config_io:
    banksel ANSEL
    clrf    ANSEL   ;
    clrf    ANSELH  ; pines digitales
    
    banksel	TRISA
    clrf    TRISA	    ;puerto A para ensenar el ontador del tmr1
    bcf	    TRISB,0	    ;led intermitente
    clrf    TRISC	    ;7 segmentos decimal
    bcf	    TRISD,0	    ;transistor 0, decenas
    bcf	    TRISD,1	    ;transistor 1, unidades
    
    banksel PORTA	;todas las salidas empiecen en 0
    clrf    PORTA
    bcf	    PORTB,0	    
    clrf    PORTB
    clrf    PORTC
    bcf	    PORTD,0		
    bcf	    PORTD,1		
    return

config_clock:
    banksel OSCCON
    bsf	    IRCF2   ;1
    bsf	    IRCF1   ;1
    bcf	    IRCF0   ;0	    oscilador a 4MHz
    bsf	    SCS	    ;se utiliza el oscilador como el reloj interno
return
    
config_tmr0:
    banksel OPTION_REG
    bcf	    T0CS    ;reloj interno
    bcf	    PSA	    ;prescaler asignado al TMR0
    bcf	    PS2	    ;0
    bsf	    PS1	    ;1
    bcf	    PS0	    ;0  010, escala de 1:8
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
    bsf	    TMR1IE  ;interrupcion tmr1
    bsf	    TMR2IE  ;interrupcion tmr2
    
    
    banksel PORTA
    bsf	    GIE	    ;interrupciones globales
    bsf	    PEIE    ;interrupciones perifericas
    
    bcf	    TMR1IF  ;bandera tmr1
    bcf	    TMR2IF  ;bandera tmr2
    
    ;bsf	    T0IF    ;interrupcion tmr0
    ;bsf	    T0IE    ;bandera tmr0
    
    return
    
;-------------------------------------------------------------------------------
; Rutinas led intermitente
;-------------------------------------------------------------------------------
intermitente:
    movf    aux+2, w	;
    movwf   PORTB	;pasar variable incrementada a puerto b
    return
    ;9D
;-------------------------------------------------------------------------------
; Rutinas contador tmr0 1s 
;-------------------------------------------------------------------------------
div_10:
    ;call    lim_contador    ;ve que el contador no se pase de 99
    movf    aux+1, w
    wdivl   10, cos_dec, res_dec    ;divir entre 10 el valor del contador
    movf    cos_dec, w
    movwf   resultado_div
    movf    res_dec, w
    movwf   redivisor
    return

lim_contador:
    movf    aux+1,w
    sublw   100
    btfss   STATUS, 2	;si el valor de la resta es 0 se salta la instruccion
    goto    div_10	;la resta no dio 0
    clrf    aux+1	;la resta da 0
    return
//hay que limitarlo y luego dividir
preparar_display7_dec:
    movf    resultado_div, w
    call    tabla_7seg
    movwf   display_7dec    ;decenas
    
    movf    redivisor, w
    call    tabla_7seg
    movwf   display_7dec+1  ;unidades
    return

