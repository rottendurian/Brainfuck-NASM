global _start

section .data
    bf_table dq _bf_endp, _bf_incptr, _bf_decptr, _bf_inc, _bf_dec, _bf_in, _bf_out, _bf_loop, _bf_endl

    bytecodejumptable db 3,5,4,6,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,0,8

section .bss
    handler resq 1
    bf_stack_start resq 1
    bf_instruction_start resq 1
    bf_buffer_read resb 255
    bf_buffer_in resb 255
section .text
_start:
    mov rbp, rsp

    ;access stack
    mov rax, [rbp]
    cmp rax, 2
    jl _bf_end
    
    mov rdi, [rbp+16]
    mov rsi, 0 ;read file
    mov rdx, 0
    mov rax, 2
    syscall

    mov [handler], rax
    sub rsp, 10

    ;stack setup
    sub rsp, 30000
    mov [bf_stack_start], rsp
    sub rsp, 2000
    mov [bf_instruction_start], rsp
    sub rsp, 2

    ;read instructions
    mov rbp, rsp
    mov r10, 0
    call _bf_bufferread


    mov r9, [bf_instruction_start]
    mov r10, [bf_stack_start]
    mov r12, bf_buffer_in

    jmp _bf_run

;reserve rax, rdi, rsi, rdx
;r9 instruction ptr
;r10 table ptr
;r11 loop ptr


_bf_run: ;jump table
    xor rax, rax
    mov al, byte [r9]
    jmp [bf_table+rax*8]
    _bf_run_ret:
    inc r9
jmp _bf_run
_bf_endp:
    mov rdi, 3
    mov rax, 60
    syscall
_bf_incptr:
    inc r10
jmp _bf_run_ret
_bf_decptr:
    dec r10
jmp _bf_run_ret
_bf_inc:
    inc byte [r10]
jmp _bf_run_ret
_bf_dec:
    dec byte [r10]
jmp _bf_run_ret
_bf_in:
    cmp [r12], byte 0
    jne _bf_in_ne

    mov rsi, bf_buffer_in
    xor rax, rax
    xor rdi, rdi
    mov rdx, 255
    syscall

    mov r12, bf_buffer_in
    mov rax, [r12]
    mov [r10], rax
jmp _bf_run_ret
    _bf_in_ne:
        inc r12
    mov rax, [r12]
    mov [r10], rax
jmp _bf_run_ret
_bf_out:
    mov rsi, r10
    mov rdx, 1
    mov rax, 1
    mov rdi, 1
    syscall
jmp _bf_run_ret
_bf_loop:
    push r9
    
jmp _bf_run_ret
_bf_endl:
    cmp [r10],byte 0
    je _bf_endl_end
    pop r9
    dec r9
    
jmp _bf_run_ret
_bf_endl_end:
    add rsp, 8
    jmp _bf_run_ret

_bf_bufferread:
    mov rax, 17
    mov rdi, [handler]
    mov rsi, bf_buffer_read
    mov rdx, 255
    syscall
    add r10, rax
    mov r11, rax
    cmp rax, 0
    je _bf_bufferread_end

    xor r9, r9

    _bf_improved_bufferead_loophead:
        mov al, byte [bf_buffer_read+r9]
        sub al, 43
        jl _bf_improved_bufferead_loop_unmet
        cmp al, 50
        jg _bf_improved_bufferead_loop_unmet
    _bf_improved_bufferead_loop_met:
        mov cl, [bytecodejumptable+rax]
        cmp cl, 0
        je _bf_improved_bufferead_loop_unmet
        mov [rbp], cl
        inc rbp
    _bf_improved_bufferead_loop_unmet:
        inc r9
        dec r11
        cmp r11, 0
        je _bf_bufferread
        jmp _bf_improved_bufferead_loophead

;+ 43 3
;, 44 5
;- 45 4
;. 46 6
;< 60 2
;> 62 1
;[ 91 7
;] 93 8

    ;_bf_bufferread_loophead:
    ;    mov al, byte [bf_buffer_read+r9]
    ;    mov rcx, 1
    ;    cmp al, ">"
    ;    je _bf_bufferead_loop_met
    ;    inc rcx
	;     cmp al, "<"
    ;    je _bf_bufferead_loop_met
	;     inc rcx
    ;    cmp al, "+"
    ;    je _bf_bufferead_loop_met
	;     inc rcx
    ;    cmp al, "-"
    ;    je _bf_bufferead_loop_met
	;     inc rcx
    ;    cmp al, ","
    ;    je _bf_bufferead_loop_met
	;     inc rcx
    ;    cmp al, "."
    ;    je _bf_bufferead_loop_met
	;     inc rcx
    ;    cmp al, "["
    ;    je _bf_bufferead_loop_met
    ;    inc rcx
    ;    cmp al, "]"
    ;    je _bf_bufferead_loop_met
    ;    jne _bf_bufferead_loop_unmet
    ;_bf_bufferead_loop_met:
    ;    mov [rbp], rcx
    ;    inc rbp
    ;_bf_bufferead_loop_unmet:
    ;    inc r9
    ;    dec r11
    ;    cmp r11, 0
    ;    je _bf_bufferread
    ;    jmp _bf_bufferread_loophead

_bf_bufferread_end:
ret

_bf_end:
    mov rdi, 1
    mov rax, 60
    syscall


