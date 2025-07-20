[org 0x7C00]

start:
    mov si, intro_msg
    call print_string

shell_loop:
    mov si, prompt
    call print_string
    call read_input
    call new_line

    ; check commands
    mov si, input_buffer
    mov di, cmd_clear
    call strcmp
    cmp al, 1
    je do_clear

    mov si, input_buffer
    mov di, cmd_help
    call strcmp
    cmp al, 1
    je do_help

    mov si, input_buffer
    mov di, cmd_halt
    call strcmp
    cmp al, 1
    je do_halt

    mov si, input_buffer
    mov di, cmd_mf
    call strcmp
    cmp al, 1
    je do_mf

    ; unknown
    mov si, unknown_cmd
    call print_string
    call new_line
    jmp shell_loop

; ---------- Commands ----------
do_clear:
    call clear_screen
    jmp shell_loop

do_help:
    mov si, help_msg
    call print_string
    call new_line
    jmp shell_loop

do_halt:
    hlt
    jmp $

do_mf:
    mov si, version_msg
    call print_string
    call new_line
    mov si, logo
    call print_string
    call new_line
    jmp shell_loop

; ---------- Functions ----------

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

read_input:
    mov di, input_buffer
    mov cx, 0          ; keep track of characters
.read_char:
    mov ah, 0x00
    int 0x16           ; wait for key
    cmp al, 0x08       ; backspace?
    jne .not_backspace

    cmp cx, 0
    je .read_char      ; nothing to erase
    dec di
    dec cx
    mov al, 0x08
    mov ah, 0x0E
    int 0x10           ; move cursor back
    mov al, ' '
    int 0x10           ; erase char
    mov al, 0x08
    int 0x10           ; move cursor back again
    jmp .read_char

.not_backspace:
    cmp al, 0x0D       ; Enter?
    je .done
    stosb
    inc cx
    mov ah, 0x0E
    int 0x10
    jmp .read_char
.done:
    mov al, 0
    stosb
    ret

new_line:
    mov ah, 0x0E
    mov al, 0x0A
    int 0x10
    mov al, 0x0D
    int 0x10
    ret

strcmp:
.next:
    lodsb
    mov bl, [di]
    inc di
    cmp al, bl
    jne .fail
    or al, al
    jnz .next
    mov al, 1
    ret
.fail:
    mov al, 0
    ret

clear_screen:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    ret

; ---------- Data ----------
intro_msg     db "Booted into Assembly Shell", 0
prompt        db "KERNEL> ", 0
unknown_cmd   db "Command not found.", 0
help_msg      db "Available: clear, help, halt, mf", 0
version_msg   db "MF Kernel v0.1.0 by Yash", 0

logo:
    db "----XOXO----", 0x0A
    db "Minimal Kernel ", 0

cmd_clear     db "clear", 0
cmd_help      db "help", 0
cmd_halt      db "halt", 0
cmd_mf        db "mf", 0

input_buffer  times 64 db 0

times 510-($-$$) db 0
dw 0xAA55
