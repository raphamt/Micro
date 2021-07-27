        PUBLIC  __iar_program_start
        PUBLIC  __vector_table
       

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

SYSCTL_RCGCGPIO_R               EQU     0x400FE608
SYSCTL_PRGPIO_R		        EQU     0x400FEA08
PORTEN_BIT                      EQU     1000100100000b        ; Habilita portas (F, N e J)
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

GPIO_PORTJ_DATA_MASKED_R    	EQU     0x40060000
GPIO_PORTJ_DATA_R    	        EQU     0x400603FC
GPIO_PORTJ_DIR_R     	        EQU     0x40060400
GPIO_PORTJ_DEN_R     	        EQU     0x4006051C
GPIO_PORTJ_PUR_R                EQU     0x40060510

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
          MOV R2, #00000011b         

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

;inicia a porta J com os bits dos botoes
          MOV R2, #00010011b 
          
;add o input dos botoes
          LDR R0, =GPIO_PORTJ_DIR_R
          LDR R1, [R0]
          BIC R1, R2   
          STR R1, [R0]
          
;ativa a função digital
          LDR R0, =GPIO_PORTJ_DEN_R
          LDR R1, [R0]
          ORR R1, R2 
          STR R1, [R0]
          
;habilita o pullup
          LDR R0, =GPIO_PORTJ_PUR_R
          LDR R1, [R0]
          ORR R1, R2 
          STR R1, [R0]

          BX LR

;altera os leds com a nova configuração
atualiza_leds 
        PUSH {R1-R4}
        
;porta N e F e testa o led 3 e 4
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

;cria uma função debounce para evitar histerese
atraso_debounce
     PUSH {R0}
     MOVT R0, #0x0005 

atraso_debounce_loop
     CBZ R0, atraso_debounce_end
     SUB R0, R0, #1
     B atraso_debounce_loop 
     
atraso_debounce_end
     POP {R0}
     BX LR

__iar_program_start
        
;inicia as portas e zera o contador        
main    
        BL init 
        MOV R0, #0
        
        
loop	
        BL atualiza_leds
        
        LDR R7, = GPIO_PORTJ_DATA_MASKED_R 
        
        LDR R2, [R7,#1100b] 
        MOVS R3,R2

;controle dos botões
notpressed_state
        MOVS R2, R3 
        BL atraso_debounce
notpressed_state_loop
        LDR R3, [R7,#1100b]
        CMP R2,R3
        BNE pressed_state
        B notpressed_state_loop

pressed_state
        MOV R2, R3 
        CMP R2,#0x2
        ITE HS
          ADDHS R0,#1 
          SUBLO R0,#1 
 ;apos add no contador reseta se chegar a 15
        CMP R0,#16 
        IT HS
          MOVHS R0,#0
        
        BL atualiza_leds 
        BL atraso_debounce
        
pressed_state_loop
        LDR R3, [R7,#1100b]
        CMP R2,R3
        BNE notpressed_state
        B pressed_state_loop
      
        
end_loop
        B end_loop

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
