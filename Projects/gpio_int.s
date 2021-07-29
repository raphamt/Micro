        PUBLIC  __iar_program_start
        PUBLIC  GPIOJ_Handler
        EXTERN  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

; System Control definitions
SYSCTL_RCGCGPIO_R       EQU     0x400FE608
SYSCTL_PRGPIO_R		EQU     0x400FEA08
PORTF_BIT               EQU     0000000000100000b ; bit  5 = Port F
PORTJ_BIT               EQU     0000000100000000b ; bit  8 = Port J
PORTN_BIT               EQU     0001000000000000b ; bit 12 = Port N

; NVIC definitions
NVIC_BASE               EQU     0xE000E000
NVIC_EN1                EQU     0x0104
VIC_DIS1                EQU     0x0184
NVIC_PEND1              EQU     0x0204
NVIC_UNPEND1            EQU     0x0284
NVIC_ACTIVE1            EQU     0x0304
NVIC_PRI12              EQU     0x0430

; GPIO Port definitions
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE    	EQU     0x40060000
GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_DIR                EQU     0x0400
GPIO_IS                 EQU     0x0404
GPIO_IBE                EQU     0x0408
GPIO_IEV                EQU     0x040C
GPIO_IM                 EQU     0x0410
GPIO_RIS                EQU     0x0414
GPIO_MIS                EQU     0x0418
GPIO_ICR                EQU     0x041C
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C

;declara��o do delay e dos leds  
DELAY                    EQU     0x005F
LEDN_1                   EQU     00010b
LEDN_2                   EQU     00001b
LEDF_2                   EQU     00001b
LEDF_1                   EQU     10000b


; ROTINAS DE SERVI�O DE INTERRUP��O

; GPIOJ_Handler: Interrupt Service Routine for port GPIO J
; Utiliza R11 para se comunicar com o programa principal
;alterado para verificar se a interrup��o � na porta 10b ou 01b
GPIOJ_Handler:
        PUSH {R3}
        MOV R0, #00000011b ; ACK do bit 0
        LDR R1, =GPIO_PORTJ_BASE
        STR R0, [R1, #GPIO_ICR]
        LDR R3, [R1, #GPIO_MIS]                         
        CMP R3, #0001b
        IT EQ
        ADDEQ R11, R11, #1
        CMP R3, #0010b                                  
        IT EQ
        SUBEQ R11, R11, #1  
        POP {R3}

        BX LR ; retorno da ISR

; PROGRAMA PRINCIPAL

__iar_program_start
;habilita as portas N, F e J respectivamente       
main    MOV R0, #(PORTN_BIT)
        BL GPIO_enable
        MOV R0, #(PORTF_BIT)
        BL GPIO_enable
        MOV R0, #(PORTJ_BIT)
        BL GPIO_enable 

;habilita os bits da porta N
        LDR R0, =GPIO_PORTN_BASE                       
        MOV R1, #000000011b        ; bits 0 e 1 como sa�da    
        BL GPIO_digital_output
        BL Escrita_em_baixa

        LDR R0, =GPIO_PORTF_BASE                        
        MOV R1, #000010001b        ; bits 0 e 4 como sa�da                  
        BL GPIO_digital_output
        BL Escrita_em_baixa

        LDR R0, =GPIO_PORTJ_BASE                    
        MOV R1, #000000011b        ; bits 0 e 4 como sa�da                  
        BL GPIO_digital_input
        BL Escrita_em_baixa
        
        BL Button_int_conf         ; habilita interrup��o do bot�o SW1
;contador
        MOV R3, #0                                   

loop:   
        MOV R3, R11
        BL LED_write
        B loop

; SUB-ROTINAS

; LED_write: escreve um valor bin�rio nos LEDs D1 a D4 do kit
; R0 = valor a ser escrito nos LEDs (bit 3 a bit 0)
; Destr�i: R1, R2, R3 e R4


;habilita o GPIO da porta 0, coloca oq R2 aponta no R1
GPIO_enable:
        LDR R2, =SYSCTL_RCGCGPIO_R                      
        LDR R1, [R2]                                  
        ORR R1, R0                                   
        STR R1, [R2]                                  
check      
        LDR R2, =SYSCTL_PRGPIO_R                  
        LDR R1, [R2]                                
        TST R1, R0                                  
        BEQ check                                 
        BX LR                                    


; GPIO_digital_output: habilita sa�das digitais no port de GPIO desejado
; R0 = endere�o base do port desejado
; R1 = padr�o de bits (1) a serem habilitados como sa�das digitais
; Destr�i: R2
GPIO_digital_output:
	LDR R2, [R0, #GPIO_DIR]
	ORR R2, R1 ; configura bits de sa�da
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita fun��o digital
	STR R2, [R0, #GPIO_DEN]
        
        BX LR

; GPIO_digital_input: habilita entradas digitais no port de GPIO desejado
; R0 = endere�o base do port desejado
; R1 = padr�o de bits (1) a serem habilitados como entradas digitais
; Destr�i: R2
GPIO_digital_input:
	LDR R2, [R0, #GPIO_DIR]
	BIC R2, R1 ; configura bits de entrada
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita fun��o digital
	STR R2, [R0, #GPIO_DEN]

	LDR R2, [R0, #GPIO_PUR]
	ORR R2, R1 ; habilita resitor de pull-up
	STR R2, [R0, #GPIO_PUR]

        BX LR

; GPIO_write: escreve nas sa�das do port de GPIO desejado
; R0 = endere�o base do port desejado
; R1 = m�scara de bits a serem acessados
; R2 = bits a serem escritos
GPIO_write:
        STR R2, [R0, R1, LSL #2] ; escreve bits com m�scara de acesso
        BX LR

; GPIO_read: l� as entradas do port de GPIO desejado
; R0 = endere�o base do port desejado
; R1 = m�scara de bits a serem acessados
; R2 = bits lidos
GPIO_read:
        LDR R2, [R0, R1, LSL #2] ; l� bits com m�scara de acesso
        BX LR

Escrita_em_baixa:
        PUSH {R2}
        MOV R2, #000000000b
        STR R2, [R0, R1, LSL #2]
        POP {R2}
        BX LR

; SW_delay: atraso de tempo por software
; R0 = valor do atraso
; Destr�i: R0
Delay:
        PUSH {R0}
        MOVT R0, #(DELAY)
SW_delay:
        CBZ R0, out_delay
        SUB R0, R0, #1
        B SW_delay        
out_delay:
        POP {R0}
        BX LR


LED_write:
;leds da porta N
        PUSH {LR, R2, R4}
        AND R2, R3, #0011b
        LSR R4, R2, #1
        LSL R2, R2, #1
        ADD R2, R4
        LDR R0, =GPIO_PORTN_BASE
        MOV R1, #000000011b
        BL GPIO_write

;leds da porta F
        AND R4, R3, #0100b
        LSL R2, R4, #2
        AND R4, R3, #1000b
        LSR R4, R4, #3
        ADD R2, R4
        LDR R0, =GPIO_PORTF_BASE
        MOV R1, #000010001b
        BL GPIO_write
        POP {R4, R2}
        BL Delay
        POP {LR}
        BX LR



; Button_int_conf: configura interrup��es do bot�o SW1 do kit
; Destr�i: R0, R1 e R2
Button_int_conf:
        MOV R2, #000000011b ; bit do PJ0
        LDR R1, =GPIO_PORTJ_BASE
        
        LDR R0, [R1, #GPIO_IM]
        BIC R0, R0, R2 ; desabilita interrup��es
        STR R0, [R1, #GPIO_IM]
        
        LDR R0, [R1, #GPIO_IS]
        BIC R0, R0, R2 ; interrup��o por transi��o
        STR R0, [R1, #GPIO_IS]
        
        LDR R0, [R1, #GPIO_IBE]
        BIC R0, R0, R2 ; uma transi��o apenas
        STR R0, [R1, #GPIO_IBE]
        
        LDR R0, [R1, #GPIO_IEV]
        BIC R0, R0, R2 ; transi��o de descida
        STR R0, [R1, #GPIO_IEV]
        
        LDR R0, [R1, #GPIO_ICR]
        ORR R0, R0, R2 ; limpeza de pend�ncias
        STR R0, [R1, #GPIO_ICR]
        
        LDR R0, [R1, #GPIO_IM]
        ORR R0, R0, R2 ; habilita interrup��es no port GPIO J
        STR R0, [R1, #GPIO_IM]

        MOV R2, #0xE0000000 ; prioridade mais baixa para a IRQ51
        LDR R1, =NVIC_BASE
        
        LDR R0, [R1, #NVIC_PRI12]
        ORR R0, R0, R2 ; define prioridade da IRQ51 no NVIC
        STR R0, [R1, #NVIC_PRI12]

        MOV R2, #10000000000000000000b ; bit 19 = IRQ51
        MOV R0, R2 ; limpa pend�ncias da IRQ51 no NVIC
        STR R0, [R1, #NVIC_UNPEND1]

        LDR R0, [R1, #NVIC_EN1]
        ORR R0, R0, R2 ; habilita IRQ51 no NVIC
        STR R0, [R1, #NVIC_EN1]
        
        BX LR


        END