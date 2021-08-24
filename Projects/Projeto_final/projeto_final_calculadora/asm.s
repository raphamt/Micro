        PUBLIC  __iar_program_start
        EXTERN  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

; System Control definitions
SYSCTL_BASE             EQU     0x400FE000
SYSCTL_RCGCGPIO         EQU     0x0608
SYSCTL_PRGPIO		EQU     0x0A08
SYSCTL_RCGCUART         EQU     0x0618
SYSCTL_PRUART           EQU     0x0A18
; System Control bit definitions
PORTA_BIT               EQU     000000000000001b ; bit  0 = Port A
PORTF_BIT               EQU     000000000100000b ; bit  5 = Port F
PORTJ_BIT               EQU     000000100000000b ; bit  8 = Port J
PORTN_BIT               EQU     001000000000000b ; bit 12 = Port N
UART0_BIT               EQU     00000001b        ; bit  0 = UART 0

; NVIC definitions
NVIC_BASE               EQU     0xE000E000
NVIC_EN1                EQU     0x0104
VIC_DIS1                EQU     0x0184
NVIC_PEND1              EQU     0x0204
NVIC_UNPEND1            EQU     0x0284
NVIC_ACTIVE1            EQU     0x0304
NVIC_PRI12              EQU     0x0430

; GPIO Port definitions
GPIO_PORTA_BASE         EQU     0x40058000
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
GPIO_AFSEL              EQU     0x0420
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C
GPIO_PCTL               EQU     0x052C

; UART definitions
UART_PORT0_BASE         EQU     0x4000C000
UART_FR                 EQU     0x0018
UART_IBRD               EQU     0x0024
UART_FBRD               EQU     0x0028
UART_LCRH               EQU     0x002C
UART_CTL                EQU     0x0030
UART_CC                 EQU     0x0FC8
;UART bit definitions
TXFE_BIT                EQU     10000000b ; TX FIFO full
RXFF_BIT                EQU     01000000b ; RX FIFO empty
BUSY_BIT                EQU     00001000b ; Busy


; PROGRAMA PRINCIPAL
s
__iar_program_start
        
main:   MOV R2, #(UART0_BIT)
	BL UART_enable ; habilita clock ao port 0 de UART

        MOV R2, #(PORTA_BIT)
	BL GPIO_enable ; habilita clock ao port A de GPIO
        
	LDR R0, =GPIO_PORTA_BASE
        MOV R1, #00000011b ; bits 0 e 1 como especiais
        BL GPIO_special

	MOV R1, #0xFF ; mascara das funcoes especiais no port A (bits 1 e 0)
        MOV R2, #0x11  ; funcoees especiais RX e TX no port A (UART)
        BL GPIO_select

	LDR R0, =UART_PORT0_BASE
        BL UART_config ; configura perif?rico UART0
        
        ; recepcao e envio de dados pela UART utilizando sondagem (polling)
        ; resulta em um "eco": dados recebidos sao retransmitidos pela UART
        
        BL reset
        


loop:
wrx:    LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #RXFF_BIT ; receptor cheio?
        BEQ wrx
        LDR R1, [R0] ; l? do registrador de dados da UART0 (recebe) - SALVA EM R1
        
        ;Verificação do valor lido  
        CMP R1, #0x2A ;Se for uma multiplicação(*)
        BEQ multiply
        
        CMP R1, #0x2B ;Se for uma Soma(+)
        BEQ sum
        
        CMP R1, #0x2D ;Se for uma subração(-)
        BEQ subtraction
        
        CMP R1, #0x2F ;Se for uma divisão(/)
        BEQ division
        
        CMP R1, #0x30 ;Se a condição < 0x30 volta pra ler a serial sem tomar nenhuma ação
        BLO loop
        
        CMP R1, #0x39 ;Se a condição estiver entre 0x30< condição <= 0x39 ele vai para ascii2num 
        BLS ascii2num
        
        CMP R1, #0x3D ;se igual
        BEQ equal

        B loop        ; Se o valor lido não for nenhum acima, volta para ler outro valor, até ser que seja válido

;Ele transforma o valor lido em ascii para um numero
ascii2num:
        ADD R10, R10, #1 ; Soma +1 no contador de digitos, para ter o controle de digitos a ser escrito
        CMP R10, #4 ; Verifica se o contador é > 4
        BHI loop    ; Se o contador for, a entrada sera invalida, voltando para o loop 
        MOV R2, #10 ; Salva 10 no auxiliar R2 para ser usado na multiplicação
        MULS R5, R5, R2; Multiplica R5 por 10 para fazer o deslocamento decimal
        SUBS R2, R1, #0x30 ; conversão de um numero lido de ascii para o numero e salvando em R2
        ADD R5, R5, R2 ; Soma o valor lido no R5
        B wtx ; Mostra o digito lido na serial


multiply:
        CMP R3, #0  ; Verifica se ja foi inserido uma operação                          
        BNE loop    ; Se ja foi inserido uma operação ele volta para a leitura 
        CMP R10, #0 ; Verifica se ja foi digitado um numero                     
        BEQ loop    ; Se nao for voltara para o loop da leitura                         
        MOV R4, R5  ; R4 recebe o valor anteriormente digitado                          
        MOV R5, #0  ; R5 recebe 0                                               
        MOV R3, #1  ; R3 recebe o valor referente a multiplicação                       
        MOV R10, #0 ; O contador de digitos recebe o valor 0                    
        B wtx       ; Printa o simbolo da operação                              
sum:
        CMP R3, #0   ; Verifica se ja foi inserido uma operação                
        BNE loop     ; Se ja foi inserido uma operação ele volta para a leitura                                              
        CMP R10, #0  ; Verifica se ja foi digitado um numero                                 
        BEQ loop     ; Se nao for voltara para o loop da leitura                                     
        MOV R4, R5   ; R4 recebe o valor anteriormente digitado                      
        MOV R5, #0   ; R5 recebe 0                                                                   
        MOV R3, #2   ; R3 recebe o valor referente a Soma                                                   
        MOV R10, #0  ; O contador de digitos recebe o valor 0                                        
        B wtx        ; Printa o simbolo da operação                                                                  
subtraction:
        CMP R3, #0  ; Verifica se ja foi inserido uma operação                 
        BNE loop    ; Se ja foi inserido uma operação ele volta para a leitura
        CMP R10, #0 ; Verifica se ja foi digitado um numero                   
        BEQ loop    ; Se nao for voltara para o loop da leitura               
        MOV R4, R5  ; R4 recebe o valor anteriormente digitado                
        MOV R5, #0  ; R5 recebe 0                                             
        MOV R3, #3  ; R3 recebe o valor referente a subração             
        MOV R10, #0 ; O contador de digitos recebe o valor 0                  
        B wtx       ; Printa o simbolo da operação                            
division:
        CMP R3, #0  ; Verifica se ja foi inserido uma operação                
        BNE loop    ; Se ja foi inserido uma operação ele volta para a leitura
        CMP R10, #0 ; Verifica se ja foi digitado um numero                   
        BEQ loop    ; Se nao for voltara para o loop da leitura               
        MOV R4, R5  ; R4 recebe o valor anteriormente digitado                
        MOV R5, #0  ; R5 recebe 0                                             
        MOV R3, #4  ; R3 recebe o valor referente a divisão             
        MOV R10, #0 ; O contador de digitos recebe o valor 0                  
        B wtx       ; Printa o simbolo da operação                            

;Quando digitar '=' o valor será tratado nesta função
equal:
        CMP R3, #0 ; Verifica se ja foi inserido a operação corretamente
        BEQ loop ; Se não for valida, volta para o loop
        CMP R10, #0 ; Verifica se ja foi digitado o segundo numero
        BEQ loop   ;Se não for valida, volta para o loop
;print_equal_wtx:                                                              
;        LDR R2, [R0, #UART_FR] ; status da UART
;        TST R2, #TXFE_BIT ; transmissor vazio?
;        BEQ print_equal_wtx
;        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
        
        BL Calculate ; Finaliza a operação e mostra na serial o resultado
        
        BL reset   
        B loop

wtx:    LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #TXFE_BIT ; transmissor vazio?
        BEQ wtx
        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)

        B loop

reset:  
        MOV R3, #0 ; O operador recebe o valor 0
        MOV R10, #0; O contador de digitos recebe o valor 0
        MOV R4, #0 ; O primeiro numero recebe o valor 0
        MOV R5, #0 ; o segundo numero receve o valor 0
        MOV R11, #0 ; Zera o indicador de negativo e divisão por zero
        BX LR


print_Serial:
        LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #TXFE_BIT ; transmissor vazio?
        BEQ print_Serial
        STR R1, [R0] ; escreve no registrador de dados da UART0 (transmite)
        BX LR


Calculate:
        PUSH {LR}

        CMP R3, #1                             ; MULTIPICACAO
        IT EQ
          MULEQ R1, R4, R5
          
        CMP R3, #2                             ; SOMA
        IT EQ
          ADDEQ R1, R4, R5
          
        CMP R3, #3                             ; SUB
        IT EQ
          BLEQ subtration_EX
        
        CMP R3, #4                             ; DIV
        IT EQ
          BLEQ Division_EX

        BL Print_Result

        POP {PC}

subtration_EX:  
        SUBS R1, R4, R5
        ITT MI
          SUBMI R1, R5, R4 ; Executa a subtração inventendo as ordens dos operadores
          MOVMI R11, #1    ; Flag de subtração com resultado negativo
        BX LR

Division_EX:
        CMP R5, #0          ; Compara se o 2º valor é 0
        ITET EQ             ; 
          MOVEQ R11, #2     ; Se o segundo valor for 0 a flag R11 = 2 que significa erro na divisão
          UDIVNE R1, R4, R5 ; Se não for igual a 0, salva a divisão em R1
          MOVEQ R1, #0      ; Se for igual a 0, salva 0 em R1
        BX LR


Print_Result:
        PUSH {LR}
        PUSH {R1}
        MOV R1, #0X3D  ; Salva "=" em R1
        ;PUSH {LR}
        BL print_Serial ; Mostra na serial
        
        POP {R1}
        
        ;PUSH {LR}
        PUSH {R7, R8, R9}   ; Conserva os registradores

        MOV R7, #0xAA       ; Dado de stop para pilha
        PUSH {R7}           ; aplica na pilha o stop  
        MOV R7, #10
        
        MOV R2, #10  ;\n
        PUSH {R2}
        MOV R2, #13  ;\r
        PUSH {R2}


        CMP R11, #2 ;Se for divisãoo por zero, R11=2
        ITTT EQ     ;Se for, adiciona 'E' na pilha e js salta para o codigo que imprime
          MOVEQ R1, #69
          PUSHEQ {R1}   
          BEQ Print_result
        
        CMP R11, #1 ;se for negativo, printa um '-' e continua no fluxo normal
        ITTTT EQ
          PUSHEQ {R1}
          MOVEQ R1, #45 ; printa '-'
          BLEQ print_Serial
          POPEQ {R1}
        
        CMP R1, #0 ;verifica se o resultado do calculo é igual a zero (Quando nao eh div/0, pq ja teria saido do fluxo antes)
        ITTT EQ    ;Se for, acidiona 0x30 na pilha ja saltar? para o codigo que imprime
        ADDEQ R1, R1, #0x30 
        PUSHEQ {R1}
        BEQ Print_result

Decomposition:  ;Codigo responsavel pela traducao do resultado em uma pilha ASCII
        CMP R1, #0 ;Neste caso, se R1=0, significa que ja encerrou a decomposi??o
        BEQ Print_result
        
        UDIV R8, R1, R7 ;realiza a divisao do resultado por #10
        MUL R9, R8, R7 ;No aux R9 eh salvo o resultado da divisao anterior vezes #10
        SUB R9, R1, R9 ;No aux fica salvo o valor do resto da divisao do resultado por #10 ( R9=(R1-(R1/#10)) )
        ADD R9, R9, #0x30 ;soma-se #0x30 para converter em ASCII
        PUSH {R9} ;coloca na pilha
        MOV R1, R8 ;R1 receve o valor do resultado da divisao de R1 por #10
        B Decomposition ;retorna para decompor o restante do resultado

Print_result: ;vai tirando os valores da pilha e imprimindo, ate chegar no valor 0xAA, adicionado antes de escrever a saida do programa
        POP {R1}
        CMP R1, #0xAA
        IT EQ
        BEQ Finish_Calculate
        BL print_Serial
        B Print_result

Finish_Calculate:
        POP {R7, R8, R9}
        POP {PC}

;===============================================================================;
   
;Subrotinas ja disponibilizadas no exemplo uart-2

; SUB-ROTINAS

;----------
; UART_enable: habilita clock para as UARTs selecionadas em R2
; R2 = padr?o de bits de habilitacao das UARTs
; Destr?i: R0 e R1
UART_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCUART]
	ORR R1, R2 ; habilita UARTs selecionados
	STR R1, [R0, #SYSCTL_RCGCUART]

waitu	LDR R1, [R0, #SYSCTL_PRUART]
	TEQ R1, R2 ; clock das UARTs habilitados?
	BNE waitu

        BX LR
        
; UART_config: configura a UART desejada
; R0 = endereco base da UART desejada
; Destr?i: R1
UART_config:
        LDR R1, [R0, #UART_CTL]
        BIC R1, #0x01 ; desabilita UART (bit UARTEN = 0)
        STR R1, [R0, #UART_CTL]

        ; clock = 16MHz, baud rate = 9600 bps
        MOV R1, #104
        STR R1, [R0, #UART_IBRD]
        MOV R1, #11
        STR R1, [R0, #UART_FBRD]
        
        ; 8 bits, 1 stop, parity odd, FIFOs disabled, no interrupts
        MOV R1, #01100010b
        STR R1, [R0, #UART_LCRH]
        
        ; clock source = system clock
        MOV R1, #0x00
        STR R1, [R0, #UART_CC]
        
        LDR R1, [R0, #UART_CTL]
        ORR R1, #0x01 ; habilita UART (bit UARTEN = 1)
        STR R1, [R0, #UART_CTL]

        BX LR



; GPIO_special: habilita funcoes especiais no port de GPIO desejado
; R0 = endereco base do port desejado
; R1 = padrao de bits (1) a serem habilitados como funcoes especiais
; Destroi: R2
GPIO_special:
	LDR R2, [R0, #GPIO_AFSEL]
	ORR R2, R1 ; configura bits especiais
	STR R2, [R0, #GPIO_AFSEL]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita funcao digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_select: seleciona funcoes especiais no port de GPIO desejado
; R0 = endereco base do port desejado
; R1 = mascara de bits a serem alterados
; R2 = padr?o de bits (1) a serem selecionados como funcoes especiais
; Destroi: R3
GPIO_select:
	LDR R3, [R0, #GPIO_PCTL]
        BIC R3, R1
	ORR R3, R2 ; seleciona bits especiais
	STR R3, [R0, #GPIO_PCTL]

        BX LR
;----------

; GPIO_enable: habilita clock para os ports de GPIO selecionados em R2
; R2 = padrao de bits de habilitacao dos ports
; Destr?i: R0 e R1
GPIO_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCGPIO]
	ORR R1, R2 ; habilita ports selecionados
	STR R1, [R0, #SYSCTL_RCGCGPIO]

waitg	LDR R1, [R0, #SYSCTL_PRGPIO]
	TEQ R1, R2 ; clock dos ports habilitados?
	BNE waitg

        BX LR

; GPIO_digital_output: habilita saidas digitais no port de GPIO desejado
; R0 = endereco base do port desejado
; R1 = padr?o de bits (1) a serem habilitados como saidas digitais
; Destroi: R2
GPIO_digital_output:
	LDR R2, [R0, #GPIO_DIR]
	ORR R2, R1 ; configura bits de saida
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita funcao digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_write: escreve nas saidas do port de GPIO desejado
; R0 = endereco base do port desejado
; R1 = mascara de bits a serem acessados
; R2 = bits a serem escritos
GPIO_write:
        STR R2, [R0, R1, LSL #2] ; escreve bits com mascara de acesso
        BX LR

; GPIO_digital_input: habilita entradas digitais no port de GPIO desejado
; R0 = endereco base do port desejado
; R1 = padrao de bits (1) a serem habilitados como entradas digitais
; Destroi: R2
GPIO_digital_input:
	LDR R2, [R0, #GPIO_DIR]
	BIC R2, R1 ; configura bits de entrada
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita funcao digital
	STR R2, [R0, #GPIO_DEN]

	LDR R2, [R0, #GPIO_PUR]
	ORR R2, R1 ; habilita resitor de pull-up
	STR R2, [R0, #GPIO_PUR]

        BX LR

; GPIO_read: le as entradas do port de GPIO desejado
; R0 = endereco base do port desejado
; R1 = mascara de bits a serem acessados
; R2 = bits lidos
GPIO_read:
        LDR R2, [R0, R1, LSL #2] ; le bits com mascara de acesso
        BX LR

; SW_delay: atraso de tempo por software
; R0 = valor do atraso
; Destr?i: R0
SW_delay:
        CBZ R0, out_delay
        SUB R0, R0, #1
        B SW_delay        
out_delay:
        BX LR

; LED_write: escreve um valor binario nos LEDs D1 a D4 do kit
; R0 = valor a ser escrito nos LEDs (bit 3 a bit 0)
; Destr?i: R1, R2, R3 e R4
LED_write:
        AND R3, R0, #0010b
        LSR R3, R3, #1
        AND R4, R0, #0001b
        ORR R3, R3, R4, LSL #1 ; LEDs D1 e D2
        LDR R1, =GPIO_PORTN_BASE
        MOV R2, #000000011b ; mascara PN1|PN0
        STR R3, [R1, R2, LSL #2]

        AND R3, R0, #1000b
        LSR R3, R3, #3
        AND R4, R0, #0100b
        ORR R3, R3, R4, LSL #2 ; LEDs D3 e D4
        LDR R1, =GPIO_PORTF_BASE
        MOV R2, #00010001b ; mascara PF4|PF0
        STR R3, [R1, R2, LSL #2]
        
        BX LR

; Button_read: le o estado dos botoes SW1 e SW2 do kit
; R0 = valor lido dos botoes (bit 1 e bit 0)
; Destroi: R1, R2, R3 e R4
Button_read:
        LDR R1, =GPIO_PORTJ_BASE
        MOV R2, #00000011b ; mascara PJ1|PJ0
        LDR R0, [R1, R2, LSL #2]
        
dbc:    MOV R3, #50 ; constante de debounce
again:  CBZ R3, last
        LDR R4, [R1, R2, LSL #2]
        CMP R0, R4
        MOV R0, R4
        ITE EQ
          SUBEQ R3, R3, #1
          BNE dbc
        B again
last:
        BX LR

; Button_int_conf: configura interrupcoes do botao SW1 do kit
; Destroi: R0, R1 e R2
Button_int_conf:
        MOV R2, #00000001b ; bit do PJ0
        LDR R1, =GPIO_PORTJ_BASE
        
        LDR R0, [R1, #GPIO_IM]
        BIC R0, R0, R2 ; desabilita interrupcoes
        STR R0, [R1, #GPIO_IM]
        
        LDR R0, [R1, #GPIO_IS]
        BIC R0, R0, R2 ; interrupCao por transicao
        STR R0, [R1, #GPIO_IS]
        
        LDR R0, [R1, #GPIO_IBE]
        BIC R0, R0, R2 ; uma transicao apenas
        STR R0, [R1, #GPIO_IBE]
        
        LDR R0, [R1, #GPIO_IEV]
        BIC R0, R0, R2 ; transicao de descida
        STR R0, [R1, #GPIO_IEV]
        
        LDR R0, [R1, #GPIO_ICR]
        ORR R0, R0, R2 ; limpeza de pendencias
        STR R0, [R1, #GPIO_ICR]
        
        LDR R0, [R1, #GPIO_IM]
        ORR R0, R0, R2 ; habilita interrupcoes no port GPIO J
        STR R0, [R1, #GPIO_IM]

        MOV R2, #0xE0000000 ; prioridade mais baixa para a IRQ51
        LDR R1, =NVIC_BASE
        
        LDR R0, [R1, #NVIC_PRI12]
        ORR R0, R0, R2 ; define prioridade da IRQ51 no NVIC
        STR R0, [R1, #NVIC_PRI12]

        MOV R2, #10000000000000000000b ; bit 19 = IRQ51
        MOV R0, R2 ; limpa pendencias da IRQ51 no NVIC
        STR R0, [R1, #NVIC_UNPEND1]

        LDR R0, [R1, #NVIC_EN1]
        ORR R0, R0, R2 ; habilita IRQ51 no NVIC
        STR R0, [R1, #NVIC_EN1]
        
        BX LR

; Button1_int_enable: habilita interrupcoes do botao SW1 do kit
; Destroi: R0, R1 e R2
Button1_int_enable:
        MOV R2, #00000001b ; bit do PJ0
        LDR R1, =GPIO_PORTJ_BASE
        
        LDR R0, [R1, #GPIO_IM]
        ORR R0, R0, R2 ; habilita interrupcoes
        STR R0, [R1, #GPIO_IM]

        BX LR

; Button1_int_disable: desabilita interrupcoes do botao SW1 do kit
; Destroi: R0, R1 e R2
Button1_int_disable:
        MOV R2, #00000001b ; bit do PJ0
        LDR R1, =GPIO_PORTJ_BASE
        
        LDR R0, [R1, #GPIO_IM]
        BIC R0, R0, R2 ; desabilita interrupcaes
        STR R0, [R1, #GPIO_IM]

        BX LR

; Button1_int_clear: limpa pendencia de interrupcoes do botao SW1 do kit
; Destroi: R0 e R1
Button1_int_clear:
        MOV R0, #00000001b ; limpa o bit 0
        LDR R1, =GPIO_PORTJ_BASE
        STR R0, [R1, #GPIO_ICR]

        BX LR

        END