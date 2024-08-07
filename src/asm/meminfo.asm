section .data
    meminfo_path db "/proc/meminfo", 0
    buffer resb 4096        ; Buffer to hold the contents of /proc/meminfo
    mem_total db "MemTotal:", 0
    mem_free db "MemFree:", 0
    newline db 10, 0

section .bss

section .text
    global _start

_start:
    ; Open /proc/meminfo
    mov rax, 2          ; sys_open
    lea rdi, [rel meminfo_path]
    xor rsi, rsi        ; O_RDONLY
    syscall

    ; Check if the file was opened successfully
    cmp rax, 0
    js _error
    mov rdi, rax        ; Save file descriptor

    ; Read the contents of /proc/meminfo
    mov rax, 0          ; sys_read
    mov rsi, buffer
    mov rdx, 4096
    syscall

    ; Print the buffer content for debugging
    mov rsi, buffer
    call print_string

    ; Close the file
    mov rax, 3          ; sys_close
    syscall

    ; Parse the contents of /proc/meminfo
    mov rdi, buffer
    lea rsi, [rel mem_total]
    call find_value
    mov rbx, rax        ; Save MemTotal value

    ; Print MemTotal for debugging
    mov rdi, rbx
    call print_number
    call print_newline

    mov rdi, buffer
    lea rsi, [rel mem_free]
    call find_value
    mov rcx, rax        ; Save MemFree value

    ; Print MemFree for debugging
    mov rdi, rcx
    call print_number
    call print_newline

    ; Calculate used memory: MemTotal - MemFree
    sub rbx, rcx
    mov rdi, rbx

    ; Print the used memory
    call print_number
    call print_newline

    ; Exit the program
    mov rax, 60         ; sys_exit
    xor rdi, rdi
    syscall

find_value:
    ; rdi - pointer to buffer
    ; rsi - pointer to key (e.g., "MemTotal:")
    push rbx
    push rcx
    push rdx

    mov rbx, rdi
    mov rcx, rsi

find_value_loop:
    mov al, byte [rbx]
    cmp al, 0
    je find_value_not_found
    mov al, byte [rcx]
    cmp al, 0
    je find_value_found
    cmp al, byte [rbx]
    jne find_value_next
    inc rbx
    inc rcx
    jmp find_value_loop

find_value_next:
    inc rbx
    mov rcx, rsi         ; Reset rcx to start of key
    jmp find_value_loop

find_value_not_found:
    xor rax, rax
    jmp find_value_done

find_value_found:
    ; Skip whitespace and colon
    mov al, byte [rbx]
    cmp al, ':'
    je .found_key
    inc rbx
    jmp find_value_found

.found_key:
    inc rbx

    ; Skip whitespace
    mov al, byte [rbx]
    cmp al, ' '
    je .skip_ws
    jmp .read_number

.skip_ws:
    inc rbx
    jmp .found_key

    ; Read the number
.read_number:
    xor rax, rax
    xor rcx, rcx

read_number_loop:
    mov al, byte [rbx]
    cmp al, '0'
    jb find_value_done
    cmp al, '9'
    ja find_value_done
    sub al, '0'
    imul rcx, 10
    add rcx, rax
    inc rbx
    jmp read_number_loop

find_value_done:
    mov rax, rcx
    pop rdx
    pop rcx
    pop rbx
    ret

print_string:
    ; rsi - pointer to string
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rdx, 4096       ; max length to print
    syscall
    ret

print_number:
    ; rdi - number to print
    push rbx
    push rcx
    push rdx

    mov rax, rdi
    mov rcx, 10
    xor rbx, rbx
    cmp rax, 0
    jne .print_number_loop

    ; Special case for zero
    mov rbx, '0'
    call print_char
    jmp .print_number_done

.print_number_loop:
    xor rdx, rdx
    div rcx
    add dl, '0'
    push rdx
    inc rbx
    test rax, rax
    jnz .print_number_loop

.print_number_print:
    dec rbx
    js .print_number_done
    pop rax
    call print_char
    jmp .print_number_print

.print_number_done:
    pop rdx
    pop rcx
    pop rbx
    ret

print_char:
    ; rdi - character to print
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    lea rsi, [rsp-1]
    mov byte [rsi], dil
    mov rdx, 1
    syscall
    ret

print_newline:
    mov rdi, 10         ; Newline character
    call print_char
    ret

_error:
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; Exit code 1
    syscall

