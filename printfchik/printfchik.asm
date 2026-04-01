default rel

section .rodata 
    jumpTable:
        %assign i 0
        %rep 256
            %if i == 's'
                dq PrintStr
            %elif i == 'c'
                dq PrintChar
            %elif i == 'd'
                dq PrintDec
            %elif i == 'x'
                dq PrintHex
            %elif i == 'o'
                dq PrintOct
            %elif i == 'b'
                dq PrintBin
            %elif i == '%'
                dq PrintPercent
            %else
                dq ErrorSpec
            %endif
            %assign i i + 1
        %endrep
    
    Base2 equ 1
    Base8 equ 3
    Base10 equ 10
    Base16 equ 4
    Percent equ '%'
    EndStr equ 0
    ByteConst equ 8
    SysWrite equ 1
    STDOUT equ 1

section .bss
    buffer      resb 10
    sizeBuffer  equ $ - buffer

section .text
    global PrintfChik


; Трамплин для аргументов + rbp + cld
; Умирают: r10
PrintfChik:
    pop r10          
    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push r10         

    push rbp
    mov rbp, rsp

    push rbx
    push r12
    push r13

    cld
    mov rbx, rdi
    xor r12, r12
    xor r13, r13

; Сравнивает текущий символ с \0 и % и делает грязь. Иначе - закидывает в буффер символ
; Умирают: al
Iterator:
    mov al, [rbx]
    cmp al, EndStr
    je Finish

    cmp al, Percent
    je Parser

    call AddChar

; Двигает указатель на след символ
; Умирают: rbx
NextPipe:
    inc rbx
    jmp Iterator


; Парсит след символ за % и прыгает по нему
; Умирают: rdx, rax, rdx
Parser:
    inc rbx
    movzx rax, byte [rbx]
    
    lea rdx, [jumpTable]
    jmp [rdx + rax * ByteConst]


; Печатает процент
; Умирают: al
PrintPercent:
    mov al, Percent
    call AddChar
    jmp NextPipe

; Печатает символ
; Умирают: al
PrintChar:
    call GetArg
    call AddChar
    jmp NextPipe

; Печатает символ за проуцентом
; Умирают: al
ErrorSpec:
    mov al, [rbx]
    call AddChar
    jmp NextPipe

; Получает аргумент из стека и загружает число в виде строки в буффер
; Умирают: rax, r10
PrintDec:
    call GetArg
    movsx rax, eax
    mov r10, Base10
    test rax, rax
    jns ConvertNe2

    push rax
    mov al, '-'
    call AddChar
    pop rax
    neg rax

; Происходит деление числа на Base который находится в r10 и закидывается в буффер строку
; Умирают: rcx, rdx, rcx
ConvertNe2:
    xor rcx, rcx

Cyrcle:
    xor rdx, rdx
    div r10
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz Cyrcle
    jmp PopSym

; Далее говорим про все принты с основанием степени двойки:
; Получает аргумент из стека и вызывают конвертер из числа в строку
; Умирают: r11
PrintHex:
    call GetArg
    mov r11, Base16
    jmp Convert2base

PrintOct:
    call GetArg
    mov r11, Base8
    jmp Convert2base

PrintBin:
    call GetArg
    mov r11, Base2
    jmp Convert2base

; Говорим о 4 след метках:
; Делаем маску, а потом переводим число(rax) в строку shr на степень двойки
; Умирают: rcx, r8, rdx, rax
Convert2base:
    xor rcx, rcx
    mov r8, 1
    push rcx
    mov cl, r11b
    shl r8, cl
    pop rcx
    dec r8

Cyrcle2base:
    mov rdx, rax
    and rdx, r8
    
    push rcx
    mov cl, r11b
    shr rax, cl 
    pop rcx

    cmp dl, 9
    jbe IsDigit2base
    add dl, 7

IsDigit2base:
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz Cyrcle2base

PopSym:
    pop rax
    call AddChar
    loop PopSym
    jmp NextPipe


; Печать строки, получает в rsi указатель на начало, сравнивает указатель с 0 и иначе печатает в буффер
; Death: rsi, al
PrintStr:
    call GetArg
    mov rsi, rax
    test rsi, rsi
    jz NextPipe

StringCycle:
    mov al, [rsi]
    cmp al, EndStr
    je NextPipe
    call AddChar
    inc rsi
    jmp StringCycle

; Закидывает в буффер символ если размера нехватает буффер выводится
; Death: rdx, r12
AddChar:
    lea rdx, [buffer]
    mov [rdx + r12], al
    inc r12
    cmp r12, sizeBuffer
    jb EndAddChar
    call FlushBuf

EndAddChar:
    ret


; Сброс буффера в stdout через прерывание
; Death: r12
FlushBuf:
    test r12, r12
    jz Empty

    push rcx
    push r11
    push rdi
    push rsi
    push rdx
    push rax

    mov rax, SysWrite
    mov rdi, STDOUT
    lea rsi, [buffer]
    mov rdx, r12
    syscall

    pop rax
    pop rdx
    pop rsi
    pop rdi
    pop r11
    pop rcx

    xor r12, r12

Empty:
    ret

; Получает из стека аргументы
; Death: rax, r13
GetArg:
    mov rax, [rbp + 2 * ByteConst + r13 * ByteConst]
    inc r13
    ret

; Выход из функции Printfchik, все аргументы "забываются(add rsp, 40)"
; Death: 
Finish:
    call FlushBuf

    pop r13
    pop r12
    pop rbx
    pop rbp

    pop r10
    add rsp, 40
    push r10
    ret

section .note.GNU-stack noalloc noexec nowrite progbits