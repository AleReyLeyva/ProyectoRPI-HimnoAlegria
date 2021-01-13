.include "inter.inc"

.text

/*Cambiamos del modo HYP a SVC */
    mrs r0,cpsr
    ldr r0, =0b11010011 @ Modo SVC, FIQ&IRQ desact
    msr spsr_cxsf,r0
    add r0,pc,#4
    msr ELR_hyp,r0 
    eret

/*Agregamos vector de interrupcion IRQ */
    mov r0, #0
    ADDEXC 0x18, irq_handler
    ADDEXC 0x1c, fiq_handler


/* Inicializo la pila en modos FIQ, IRQ y SVC */
    mov r0, #0b11010001 @ Modo FIQ, FIQ & IRQ desact
    msr cpsr_c, r0
    mov sp, #0x4000
    mov r0, #0b11010010 @ Modo IRQ, FIQ & IRQ desact
    msr cpsr_c, r0
    mov sp, #0x8000
    mov r0, #0b11010011 @ Modo SVC, FIQ & IRQ desact
    msr cpsr_c, r0
    mov sp, #0x8000000


/* Configuro GPIOs 4, 9, 10, 11, 17, 22 y 27 como salida */
    ldr r0, = GPBASE
/* guia bits xx999888777666555444333222111000 */
    ldr r1,   =0b00001000000000000001000000000000
    str r1, [r0, #GPFSEL0]
    ldr r1,   =0b00000000001000000000000000001001
    str r1, [r0, #GPFSEL1]
    ldr r1,   =0b00000000001000000000000001000000
    str r1, [r0, #GPFSEL2]

/*Programamos C1 y C3 para interrupcion */
    ldr r0, = STBASE
    ldr r1, [ r0, #STCLO ]
    add r1, r1, #2
    str r1, [ r0, #STC1 ]
    str r1, [ r0, #STC3 ]

/* Habilitamos C1 para IRQ */
    ldr r0,=INTBASE
    ldr r1, =0b0010	@ Comparador C1
    str r1,[r0, #INTENIRQ1]

/* Habilitamos C3 para FIQ */
    ldr r1,=0b10000011
    str r1, [r0, #INTFIQCON]

/* Activamos interrupciones globalmente */
    ldr r0, =0b00010011	@ Modo SVC, IRQ&FIQ activo
    msr cpsr_c, r0

/*Bucle que sondea los dos botones y actualiza la variable botonPulsado en función de cual se pulse */
    ldr r0, =GPBASE
    boton:
    ldr r1, [r0, #GPLEV0]
/* guia bits	    xx987654321098765432109876543210 */
    ands r2, r1, #0b00000000000000000000000000001000
    beq boton1
    ands r2, r1, #0b00000000000000000000000000000100
    beq boton2
    b boton

    boton1:
/*Apagamos todos los LEDs si venimos del modo 2, y reiniciamos el indexLed en 1*/
/* guia bits	xx987654321098765432109876543210 */
    ldr r3, =botonPulsado
    ldr r4, [r3]
    cmp r4, #2

    ldreq r2,  =0b00001000010000100000111000000000
    streq r2,  [r0, #GPCLR0]
    ldreq r2, =indexLed
    ldreq r4, =1
    streq r4, [r2]
    
    ldr r4, =1
    str r4, [r3]

    b boton

    boton2:
    ldr r3, =botonPulsado
    ldr r4, =2
    str r4, [r3]
    b boton

/*Rutina de Interrupcion IRQ */
    irq_handler:
    push {r0, r1, r2, r3, r4, r5}
    ldr r0, =GPBASE

/* Revisamos el boton pulsado */
    ldr r2, =botonPulsado
    ldr r4, [r2]
    cmp r4, #1
    beq MODO1
    cmp r4, #2
    beq MODO2

    IRQ:
/*Restablecemos la interrupcion en C1 */

    ldr r0, =STBASE
    ldr r2, =0b0010
    str r2, [r0, #STCS]

/* Programamos la siguiente interrupcion 
con la duracion adecuada según la nota */

    ldr r1, =arrayDuraciones
    ldr r4, =indexNota @ Cargo la direccion de memoria del index actual
    ldr r5, [r4] @ Cargo el index actual en r5
    add r5, #1
    cmp r5, #NUMNOTAS
    moveq r5, #1
    str r5, [r4]

    ldr r2, [r0, #STCLO]
    ldr r3, [r1, r5, LSL #2]
    add r2, r3
    str r2, [r0, #STC1]

/*Salimos de la interrupcion */
    pop {r0, r1, r2, r3, r4, r5}
    subs pc, lr, #4

    MODO1:

/*Comprobamos que LED toca encender */
        ldr r1, =ledsMODO1
        sub r1, #4
        ldr r4, =indexLed @ Cargo la direccion de memoria del index del led actual
        ldr r5, [r4] @ Cargo el index del led actual en r5
        cmp r5, #NUMLEDS
        moveq r5, #1
        addne r5, #1
        str r5, [r4]

/*Encendemos el LED que toque segun la variable indexLed, si todavia no se han encendido todos los leds */
        ldrne r2, [r1, r5, LSL #2]
        strne r2, [r0, #GPSET0]
        
/*Apagamos todos los LEDs si estan todos encendidos*/
/* guia bits	xx987654321098765432109876543210 */
        ldreq r2,  =0b00001000010000100000111000000000
        streq r2,  [r0, #GPCLR0]

/*Salimos del encendido*/
        b IRQ

    MODO2:
/* Apagamos todos los LEDs */
/* guia bits	xx987654321098765432109876543210 */
        ldr r2, =0b00001000010000100000111000000000
        str r2, [r0, #GPCLR0]

/*Comprobamos que LED toca encender */
        ldr r1, =ledsMODO2
        sub r1, #4
        ldr r4, =indexLed @ Cargo la direccion de memoria del index del led actual
        ldr r5, [r4] @ Cargo el index del led actual en r5
        cmp r5, #NUMLEDS
        moveq r5, #1
        addne r5, #1
        str r5, [r4]

/*Encendemos el LED que toque segun la variable indexLed */
        ldr r2, [r1, r5, LSL #2]
        str r2, [r0, #GPSET0]

/*Salimos del encendido*/
        b IRQ
    
    
/*Rutina de Interrupcion FIQ */
    fiq_handler :
    ldr r8, =GPBASE
    ldr r9, =bitBuzzer

/* Hago sonar altavoz invirtiendo estado de la variable bitBuzzer */
    ldr r10, [r9]
    eors r10, #1
    str r10, [r9], #4

/* Leemos la nueva nota desde el array */
    ldr r9, =arrayNotas
    ldr r10, =indexNota
    ldr r10, [r10]
    ldr r9, [r9, r10, LSL #2]

/* Actualizamos el estado del altavoz segun el valor de la variable bitBuzzer */

    mov r10, #0b10000 @ GPIO 4 ( altavoz )
    streq r10, [ r8, #GPSET0 ]
    strne r10, [ r8, #GPCLR0 ]

/* Reseteo del estado de la interrupcion C3 */
    ldr r8, = STBASE
    mov r10, #0b1000
    str r10, [ r8, #STCS ]
/* Programo el retardo de la interrupción con el valor de la nota extraida del array */
    ldr r10, [ r8, #STCLO ]
    add r10, r9
    str r10, [ r8, #STC3 ]
/* Salgo de la RTI */
    subs pc, lr, #4

botonPulsado: .word 1 @ Boton Pulsado
bitBuzzer: .word 0 @ Controla el estado del altavoz
indexNota: .word 1 @ Indice que recorre el array de duraciones para irq_handler
indexLed: .word 1 @ Indice que recorre el array de leds

.include "variablesGlobales.inc"
.include "leds.inc"
.include "himnoAlegria.inc"



