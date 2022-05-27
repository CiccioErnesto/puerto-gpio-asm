// Cortex-M3 Devices Generic User Guide: https://developer.arm.com/documentation/dui0552/
// STM32f103xx Family Reference Manual: https://www.st.com/resource/en/reference_manual/cd00171190-stm32f101xx-stm32f102xx-stm32f103xx-stm32f105xx-and-stm32f107xx-advanced-arm-based-32-bit-mcus-stmicroelectronics.pdf
// STM32f103c8 Datasheet: https://www.st.com/resource/en/datasheet/stm32f103c8.pdf
// Procedure Call Standard for the Arm Architecture: https://github.com/ARM-software/abi-aa/blob/main/aapcs32/aapcs32.rst
.syntax unified
.cpu cortex-m3
.fpu softvfp
.thumb

.macro defun nombre
    .section .text.\nombre
    .global \nombre
    .type \nombre, %function
\nombre:
.endm
.macro endfun nombre
    .size \nombre, . - \nombre
.endm

.set Pin__puerto,0
.set Pin__numero,4

defun Pin_init
    // R0: self, R1: puerto, R2: numPin
    str R1,[R0,#Pin__puerto]
    str R2,[R0,#Pin__numero]
    bx lr
endfun Pin_init

.set CRL,0x00
.set CRH,0x04
.set IDR,0x08
.set ODR,0x0C
.set BSRR,0x10
.set BRR,0x14
.set MASCARA_BITS_CONFIG,0xF
.set CNF_PULL_UP_O_DN,0x8

defun Pin_configura // Pin configurado en analogico significa que los 4 bits esten 0.
    // R0: self, R1: config
    push {R4-R6,LR}
    ldr R2,[R0,#Pin__puerto]
    ldr R3,[R0,#Pin__numero]
    //verificar si es CRL o CRH de acuerdo al numero de pin.
    cmp R3,#8
    bhs 0f    // Si es mayor o igual a 8 salta a 0 adelante
    movs R6,#CRL
    b 1f

0:

    movs R6,#CRH
    subs R3,#8  // Le resto 8 a R3 (numero de pin) porque esta en la parte alta 

1:

    //antes de usar esta seccion del codigo que esta a continuacion debo verificar si es CRL o CRH de acuerdo al numero de pin.
    ldr R4,[R2,#CRL]
    movs R5,#MASCARA_BITS_CONFIG
    lsls R3,#2 // multiplico por 4 la posicion
    lsls R5,R3 // asigno el valor de mascara a R5
    bics R4,R5 // todos los bits estan en 0
    mov  R12,R1
    ands R1,#MASCARA_BITS_CONFIG
    lsls R1,R3
    orrs R4,R1 // R1 ESTA LA MASCARA CON LOS VALORES QUE HAY QUE PONER PERO ANTES SE DEBE CORREGIR EN LA POSICION QUE SE DEBE PONER LA MASCARA.
    str R4,[R2,R6] // R6 AHORA CONTIENE EL VALOR SI ES CRL O CRH.
    mov R1,R12
    ands R4,R1,#MASCARA_BITS_CONFIG
    cmp R4,#CNF_PULL_UP_O_DN
    bne 0f
    ubfx R1,R1,#4,#1
    bl Pin_escribe

0:    
    pop {R4-R6,PC}
    bx lr
endfun Pin_configura



defun Pin_escribe
    // R0: self, R1: valor
    ldr R2,[R0,#Pin__puerto]
    ldr R3,[R0,#Pin__numero]
    movs R0,#1
    lsls R0,R3
    cmp R1,#0
    bne 0f
    str R0,[R2,#BRR]
    b 1f
0:
    str R0,[R2,#BSRR]
1:    
    bx lr
endfun Pin_escribe

defun Pin_lee
    // R0: self
    ldr     R1,[R0,#Pin__puerto]    // Cargamos la direccion del puerto en R1
    ldr     R2,[R0,#Pin__numero]    // Cargamos numero de pin en R2
    mov     R3,#1
    lsls    R3,R2                   // En un registro cargamos un solo en la posicion del pin a analizar
    ldr     R0,[R1,#IDR]            // Cargamos en R0 los valores de la entrada
    tst     R0,R3                       
    bne     0f                      // Si tenemos un en el pin, salta a la etiqueta 0
    mov     R0,#0                  
    b       1f
0:
    mov     R0,#1
1:
    bx lr
    // R1: valor
endfun Pin_lee
defun Pin_leeSalida
    // R0: self
    ldr     R1,[R0,#Pin__puerto]  
    ldr     R2,[R0,#Pin__numero]        
    mov     R3,#1
    lsls    R3,R2                       
    ldr     R0,[R1,#ODR]                
    tst     R0,R3                       
    bne     0f                         
    mov     R0,#0                       
    b       1f
0:
    mov     R0,#1
1:
    bx lr
    // R1: valor
endfun Pin_leeSalida
