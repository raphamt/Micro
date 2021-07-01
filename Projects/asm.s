        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start
        


main    MVN R0, #0x55       ;alocou AA hex inverso de 55 em R0 ;alocou 55 hex em R0 e inverteu os valores em R0;MOV R0, #0x55           ;aloca 55 hex em R0
        MVN R1, R0, LSL #16 ;alocou R0 inverso de 55 movimentando 4 bytes pra esquerda ;MOV R1, R0, LSL #16     ;movimenta 4 bytes pra esquerda e salva em R1
        MVN R2, R1, LSR #8  ;movimenta R1 inverso em 2 bytes para direita e salva em R2;MOV R2, R1, LSR #8      ;movimenta R1 2 bytes para direita e salva em R2
        MVN R3, R2, ASR #4  ;aloca R2 invertido e desloca um byte para direita em R3;MOV R3, R2, ASR #4      ;desloca um byte para direita
        MVN R4, R3, ROR #2  ;multiplica R3*4 hex e salva o inverso em R4;MOV R4, R3, ROR #2      ;multiplica R3*4 hex e salva em R4
        MVN R5, R4, RRX     ;multiplica R4*8 hex, salva o inverso em R5 e desloca um byte para direita;MOV R5, R4, RRX         ;multiplica R4*8 hex e salva em R5 e desloca um byte para direita

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
