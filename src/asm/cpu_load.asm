section .bss
    buffer resb 128
    prev_idle resq 1
    prev_total resq 1
    idle resq 1
    total resq 1

section .data
    filename db '/proc/stat', 0
    format db 'Current CPU Load: %d.%02d%%', 10, 0

section .text
    extern printf
    extern nanosleep
    global _start

_start:
    ; Read initial CPU times
    call read_cpu_times
    mov rax, [idle]
    mov [prev_idle], rax
    mov rax, [total]
    mov [prev_total], rax

    ; Sleep for 1 second using nanosleep
    mov rdi, timespec     ; pointer to timespec structure
    xor rsi, rsi
    call nanosleep

    ; Read CPU times again
    call read_cpu_times

    ; Calculate deltas
    mov rax, [idle]
    sub rax, [prev_idle]
    mov rbx, rax       ; idle_delta

    mov rax, [total]
    sub rax, [prev_total]
    mov rcx, rax       ; total_delta

    ; Calculate CPU usage
    mov rax, rcx
    sub rax, rbx
    imul rax, 10000
    cdq
    idiv rcx

    ; Prepare arguments for printf
    mov rdi, format
    mov rsi, rax
    mov rdx, 100
    div rdx
    mov rsi, rax
    mov rdx, rdx

    ; Print CPU load
    call printf

    ; Exit
    mov rax, 60        ; sys_exit
    xor rdi, rdi
    syscall

read_cpu_times:
    ; Open /proc/stat
    mov rax, 2         ; sys_open
    lea rdi, [rel filename]
    xor rsi, rsi       ; O_RDONLY
    syscall
    test rax, rax
    js _exit
    mov rdi, rax       ; file descriptor

    ; Read /proc/stat
    mov rax, 0         ; sys_read
    mov rsi, buffer
    mov rdx, 128
    syscall
    test rax, rax
    js _exit

    ; Close the file
    mov rax, 3         ; sys_close
    syscall

    ; Parse the buffer
    mov rsi, buffer
    call parse_cpu_times

    ret

parse_cpu_times:
    ; Skip the "cpu  " part
    add rsi, 5

    ; Read user, nice, system, idle, iowait, irq, softirq, steal
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11

    ; user
    call read_number
    ; nice
    call read_number
    ; system
    call read_number
    ; idle
    call read_number
    mov [idle], rax
    ; iowait
    call read_number
    add [idle], rax
    ; irq
    call read_number
    ; softirq
    call read_number
    ; steal
    call read_number

    ; Calculate total time
    mov rax, rbx
    add rax, rcx
    add rax, rdx
    add rax, r8
    add rax, r9
    add rax, r10
    add rax, r11
    mov [total], rax

    ret

read_number:
    xor rbx, rbx

.next_digit:
    lodsb
    sub al, '0'
    cmp al, 9
    jae .done

    imul rbx, rbx, 10
    add rbx, rax
    jmp .next_digit

.done:
    mov rax, rbx

    ret

_exit:
    ; Exit
    mov rax, 60        ; sys_exit
    mov rdi, -1
    syscall

section .data
timespec:
    dq 1              ; seconds
    dq 0              ; nanoseconds

