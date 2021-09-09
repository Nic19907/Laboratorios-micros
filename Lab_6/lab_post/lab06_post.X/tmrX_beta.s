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
restart_tmr1 macro
    movlw   0x0B
    movwf   TMR1H   ;preload high
    movlw   0x47
    movwf   TMR1L   ;preload low, 0x0B47
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
    cont_tmrX:   ;cuantas veces a terminado el tmrX dentro de un ciclo
	DS 2
	
    momento_tmrX:   ;al finalizar X ciclos con el tmrX se incrementa la variable
	DS 2
	
    display7_dec:  ;0=decenas. 1=unidades
	DS 1	
//variable de divicion
    conteo:
	DS 2
    decenas:
	DS 1
    unidades:
	DS 1
    resultado_div:  ;resultado de la divicion
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
int_tmr1:   ;reloj de 1 segund
    restart_tmr1
    incf    cont_tmrX
    movf    cont_tmrX, W
    sublw   8		;cuantas veces se debe repetir
    btfss   STATUS, 2    ;si la resta es 0 se hace 0
    goto    brake	;la resta no fue 0
    clrf    cont_tmrX	;la resta fue 0
    incf    momento_tmrX    ;ciclo competo guardarlo en esta variable
    goto    brake

int_tmr2:
    bcf	    TMR2IF
    incf    cont_tmrX+1
    movf    cont_tmrX+1, W
    sublw   10		;cuantas veces se debe repetir, 500 ms
    btfss   STATUS, 2   ;si la resta es 0 se hace 0
    goto    brake	;la resta fue 0
    clrf    cont_tmrX+1	;la resta no fue 0
    incf    momento_tmrX+1  ;ciclo competo guardarlo en esta variable
    
brake:	;salir de la interrupcion
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
    call    config_tmr1
    call    config_tmr2
    call    config_ie
    banksel	PORTA
    
//de momento ensenar el tmr1 post tabla en PORTC Y PORTD
;-------------------------------------------------------------------------------
; LOOP principal
;-------------------------------------------------------------------------------
 loop:
    call    intermitente_tmr2
    call    contador
    call    div_10
    call    preparar_display7_dec
    ;call    puertos
    goto    loop
;-------------------------------------------------------------------------------
; Rutinas de configuracion
;-------------------------------------------------------------------------------
config_io:
    banksel ANSEL
    clrf    ANSEL   ;
    clrf    ANSELH  ; pines digitales
    
    banksel	TRISA
    clrf    TRISA   ;puerto A para ensenar el ontador del tmr1
    bcf	    TRISB,0 ;led intermitente
    clrf    TRISC   ;7 segmentos decimas
    clrf    TRISD   ;7 segmentos unidades
    
    banksel PORTA
    clrf    PORTA   ;salidas empiecen en 0
    bcf	    PORTB,0 ;=    
    clrf    PORTB   ;=
    clrf    PORTC   ;=
    clrf    PORTD   ;=	
    return

config_clock:
    banksel OSCCON
    bsf	    IRCF2   ;1
    bsf	    IRCF1   ;1
    bcf	    IRCF0   ;0	    oscilador a 4MHz
    bsf	    SCS	    ;se utiliza el oscilador como el reloj interno
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
    movlw   195	    ;cuente hasta 195
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
    return
    
;-------------------------------------------------------------------------------
; Rutinas led intermitente
;-------------------------------------------------------------------------------
intermitente_tmr2:
    movf    momento_tmrX+1, w	;
    movwf   PORTB	;pasar variable incrementada a puerto b
    return
    
;-------------------------------------------------------------------------------
; Rutinas contador tmr1 1s 
;-------------------------------------------------------------------------------
contador:
    call    lim_contador
    movf    momento_tmrX, w
    movwf   PORTA
    return

lim_contador:
    movf    momento_tmrX, w
    sublw   100		    ;numero maximo disponible
    btfss   STATUS, 2	    ;si la resta es 0 se hace 0
    return		    ;la resta no fue 0
    clrf    momento_tmrX    ;la resta fue 0
    return
    
;-------------------------------------------------------------------------------
; Rutinas display 7 segmentos
;-------------------------------------------------------------------------------
div_10:
    movf    momento_tmrX, w ;cada conteo del tmr1 moverlo a W
    wdivl   10, decenas, unidades   ;dividirlo en 10
    movf    decenas, w	
    movwf   resultado_div   ;guardar decenas aqui
    
    movf    unidades, w
    movwf   resultado_div+1 ;guardar unidades aqui
    return



preparar_display7_dec:
    movf    resultado_div, w
    call    tabla_7seg
    movwf   display7_dec
    
    movf    resultado_div+1, w
    call    tabla_7seg
    movwf   display7_dec+1
    return