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

section .bss
    buffer      resb 10
    sizeBuffer  equ $ - buffer
    pointer         resq 1

section .text
    global PrintfChik
; rdi rsi rdx rcx r8 r9

; rdi - pointer to start string
PrintfChik:
    cld

    push rbp
    mov rbp, rsp

    push rbx
    push r12
    push r13

    push r9
    push r8
    push rcx
    push rdx
    push rsi

    xor r13, r13

    mov rbx, rdi
    lea rax, [buffer]
    mov [pointer], rax

Iterator:
    mov al, [rbx]
    cmp al, 0
    je Finish

    cmp al, '%'
    je Parser

    call AddChar
    jmp NextPipe

Parser:
    inc rbx
    movzx rax, byte [rbx]

    lea rdx, [jumpTable]
    jmp [rdx + rax * 8]

PrintPercent:
    mov al, '%'
    call AddChar
    jmp NextPipe

PrintChar:
    call GetArg
    call AddChar
    jmp NextPipe
ErrorSpec:
    jmp NextPipe

PrintDec:
    call GetArg
    movsx rax, eax
    mov r10, 10
    test rax, rax
    jns Converation

    push rax
    mov al, '-'
    call AddChar
    pop rax
    neg rax
    jmp Converation

PrintHex:
    call GetArg
    mov r10, 16
    jmp Converation

PrintOct:
    call GetArg
    mov r10, 8
    jmp Converation

PrintBin:
    call GetArg
    mov r10, 2
    jmp Converation

Converation:
    xor rcx, rcx
Cyrcle:
    xor rdx, rdx
    div r10
    cmp dl, 9
    jbe IsDigit
    add dl, 7
IsDigit:
    add dl, '0'
    push rdx
    inc rcx
    cmp rax, 0
    jne Cyrcle

PopSym:
    pop rax
    push rcx
    call AddChar
    pop rcx
    loop PopSym

    jmp NextPipe

PrintStr:
    call GetArg
    mov rsi, rax
    cmp rsi, 0
    je NextPipe
StringCycle:
    mov al, [rsi]
    inc rsi
    cmp al, 0
    je NextPipe

    call AddChar
    jmp StringCycle

NextPipe:
    inc rbx
    jmp Iterator

Finish:
    call FlushBuf
    add rsp, 40
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

AddChar:
    push rbx
    mov rdi, [pointer]
    mov [rdi], al
    inc rdi
    mov [pointer], rdi

    lea rdx, [buffer]
    mov rax, rdi
    sub rax, rdx
    cmp rax, sizeBuffer
    jb Norm
    call FlushBuf
Norm:
    pop rbx
    ret
FlushBuf:
    push rax
    push rdi
    push rsi
    push rdx
    push rcx
    push r11

    mov rdx, [pointer]
    lea rsi, [buffer]
    sub rdx, rsi
    jz Empty

    mov rax, 1
    mov rdi, 1
    syscall
    lea rax, [buffer]
    mov qword [pointer], rax
Empty:
    pop r11
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
    
GetArg:
    cmp r13, 5
    jae ReadStack
ReadReg:
    mov rax, r13
    shl rax, 3
    sub rax, 64
    add rax, rbp
    mov rax, [rax]
    inc r13
    ret
ReadStack:
    mov rax, r13
    sub rax, 5
    shl rax, 3
    mov rax, [rbp + 16 + rax]
    inc r13
    ret
