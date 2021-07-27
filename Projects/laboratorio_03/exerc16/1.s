        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB


;alterando a porta N bit 12
SYSCTL_RCGCGPIO_R       EQU     0x400FE608
SYSCTL_PRGPIO_R		EQU     0x400FEA08
PORTN_BIT               EQU     1000000000000b 
GPIO_PORTN_DATA_R    	EQU     0x400643FC
GPIO_PORTN_DIR_R     	EQU     0x40064400
GPIO_PORTN_DEN_R     	EQU     0x4006451C

__iar_program_start
        
;Le o estado antigo, ativa a porta N e escreve o estado novo
main    MOV R1, #PORTN_BIT
	LDR R4, =SYSCTL_RCGCGPIO_R
	LDR R0, [R4] 
	ORR R0, R1 
	STR R0, [R4] 

;le o estado, verifica se o clock da porta N esta ativo e se não está manda esperar.
        LDR R4, =SYSCTL_PRGPIO_R
wait	LDR R1, [R4] 
	TEQ R0, R1 
	BNE wait  

;inicia o bit 0, le o estado antigo, da o bit de estrada e escreve o estado novo
        MOV R1, #00000001b 
	LDR R4, =GPIO_PORTN_DIR_R
	LDR R0, [R4] 
	ORR R0, R1 
	STR R0, [R4] 

;Le o estado antigo, ativa a função digital e escreve o estado novo
	LDR R4, =GPIO_PORTN_DEN_R
	LDR R0, [R4] 
	ORR R0, R1 
	STR R0, [R4] 

;da o primeiro estado
        MOV R0, #000000001b 
 	LDR R4, = GPIO_PORTN_DATA_R
        MOV R1, #0x3FC

;o loop faz a leitura do estado da porta, muda o bit da led d2 e salva a porta alterada
loop	
        LDR R3, [R4] 
        EOR R3, R0 
        STR R3, [R4] 
        
;inicia a contante de delay e faz os clocks 1 e 3
        MOVT R3, #0x001F 
delay   CBZ R3, theend 
        SUB R3, R3, #1 
        B delay ; 
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

