        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start
        
        ;; main program begins here
main    MOV R0, #25           ;
        MOV R1, #15           ;
        BL Mul16b             ;
        B Loop                ;
                              ;
Mul16b:                       ;
        PUSH {R1}             ;poe na R1 na pilha
desloca                       ;
        CMP R1, #0            ;verifica se R1 = 0
        BEQ fim               ;se sim encerra
        LSRS R1, R1, #1       ;descoloca a direita
        ITT CS                ;verifica se maior ou  igual
          LSLCS R4, R0, R3    ;desloca a esquerda e soma em R4
          ADDCS R2, R2, R4    ;adiciona a soma em R2
        ADD R3, R3, #1        ;Add 1 em R3
        B desloca             ;repete
fim                           ;
        POP {R1}              ;retorna o valor a R1
        BX LR                 ;encerra
Loop                          ;
        B Loop                ;
        ;; main program ends here

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
