        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

SYSCTL_RCGCGPIO_R               EQU     0x400FE608
SYSCTL_PRGPIO_R		        EQU     0x400FEA08
PORTEN_BIT                      EQU     1111111111111b ; Habilita portas (F, N e J)
PORTN_LED_MASK                  EQU     0001100b
PORTF_LED_MASK                  EQU     1000100b
GPIO_PORTN_DATA_MASKED_R    	EQU     0x40064000
GPIO_PORTN_DATA_R    	        EQU     0x400643FC
GPIO_PORTN_DIR_R     	        EQU     0x40064400
GPIO_PORTN_DEN_R     	        EQU     0x4006451C

GPIO_PORTF_DATA_MASKED_R    	EQU     0x4005D000
GPIO_PORTF_DATA_R    	        EQU     0x4005D3FC
GPIO_PORTF_DIR_R     	        EQU     0x4005D400
GPIO_PORTF_DEN_R     	        EQU     0x4005D51C


; le o estado anterior, ativa a porta N e F, escreve o estado novo
init   
            MOV R2, #PORTEN_BIT
            LDR R0, =SYSCTL_RCGCGPIO_R
            LDR R1, [R0] 
            ORR R1, R2 
            STR R1, [R0]

            LDR R0, =SYSCTL_PRGPIO_R
            
; le o estado, verifica o clock e se não ele manda esperar
init_wait	
          LDR R2, [R0] 
          TEQ R1, R2 
          BNE init_wait 


;adiciona a porta N e habilita os bits de d1 e d2
          MOV R2, #00000011b ; 

;le o estado antigo, da o bit de saida e escreve o estado novo
          LDR R0, =GPIO_PORTN_DIR_R
          LDR R1, [R0] 
          ORR R1, R2 
          STR R1, [R0] 

;le o estado antigo, ativa a função digital e escreve o estado novo
          LDR R0, =GPIO_PORTN_DEN_R
          LDR R1, [R0] 
          ORR R1, R2 
          STR R1, [R0] 
          
;ativa os bits d3 e d4
          MOV R2, #00010001b 

;le o bit antigo e escreve o estado novo
          LDR R0, =GPIO_PORTF_DIR_R
          LDR R1, [R0] 
          ORR R1, R2 
          STR R1, [R0]
          LDR R0, =GPIO_PORTF_DEN_R

;le o estado antigo, ativa a função digital e escreve o estado novo
          LDR R1, [R0] 
          ORR R1, R2 
          STR R1, [R0] 
          BX LR

;altera os leds com a nova configuração
atualiza_leds 
        PUSH {R1-R4}
        
;porta N e F e testa o led 3
        LDR R1, = GPIO_PORTF_DATA_MASKED_R 
        LDR R2, = GPIO_PORTN_DATA_MASKED_R 
        AND R3, R0,#0001b
        MOVS R4, R3
        AND R3, R0,#0010b
        LSL R3, R3, #3
        ORR R3,R4
        
; altera a porta F e testa o led 2 e 1
        STR R3, [R1,#PORTF_LED_MASK] 
        AND R3, R0,#0100b
        LSR R3, R3, #2
        MOVS R4,R3
        AND R3, R0,#1000b
        LSR R3, R3, #2
        ORR R3,R4

;altera a porta N
        STR R3, [R2,#PORTN_LED_MASK] 
        

        POP {R1-R4}
        BX LR
        
     
__iar_program_start
        
main    
        BL init

        MOVS R0, #0 
; inicia e zera o contador
loop	
        
        BL atualiza_leds
        ADDS R0,#1 
        TEQ R0,#16 
        IT EQ
          MOVEQ R0,#0
;adicionou no contador e reseta quando 15
        MOVT R3, #0x005F 
        
;clocks e constante de atraso
atraso   CBZ R3, theend 
        SUB R3, R3, #1 
        B atraso 
theend 
        B loop

        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END


