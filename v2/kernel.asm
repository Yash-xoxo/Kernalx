; Minimal x86 16-bit Real Mode Boot Sector + Simple Command Monitor
; Name: YASHXOXO
; Assemble: nasm -f bin kernel.asm -o yashxoxo.img
; Boot with: qemu-system-i386 -fda yashxoxo.img

ORG 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    call clear_screen
    mov si, welcome_msg
    call print_string

main_loop:
    call print_prompt
    call read_line
    call parse_command
    jmp main_loop

; =======================
; Print Prompt
print_prompt:
    mov si, prompt
    call print_string
    ret

; =======================
; Print String (SI=string, zero-terminated)
print_string:
    pusha
.print_char:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .print_char
.done:
    popa
    ret

; =======================
; Clear Screen
clear_screen:
    mov ah, 0x06
    mov al, 0
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184F
    int 0x10
    ret

; =======================
; Read Line (max 80 chars), result at buffer
read_line:
    mov di, buffer
    mov cx, 0
.read_char:
    mov ah, 0
    int 0x16            ; BIOS: get keystroke
    cmp al, 13          ; Enter
    je .done
    cmp al, 8           ; Backspace
    je .backspace
    cmp cx, 79
    jae .read_char
    mov [di], al
    mov ah, 0x0E
    int 0x10            ; Echo char
    inc di
    inc cx
    jmp .read_char
.backspace:
    cmp cx, 0
    je .read_char
    dec di
    dec cx
    mov al, 8
    mov ah, 0x0E
    int 0x10
    mov al, ' '
    mov ah, 0x0E
    int 0x10
    mov al, 8
    mov ah, 0x0E
    int 0x10
    jmp .read_char
.done:
    mov al, 13
    mov [di], al
    inc di
    mov al, 10
    mov [di], al
    inc di
    mov al, 0
    mov [di], al
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    ret

; =======================
; Parse and Execute Command
parse_command:
    mov si, buffer

    ; skip leading spaces
.skip_spaces:
    lodsb
    cmp al, ' '
    je .skip_spaces
    dec si

    ; Check for "help"
    mov di, help_str
    call cmp_word
    jc .not_help
    mov si, help_msg
    call print_string
    ret
.not_help:

    ; Check for "about"
    mov di, about_str
    mov si, buffer
    call cmp_word
    jc .not_about
    mov si, about_msg
    call print_string
    ret
.not_about:

    ; Check for "clear"
    mov di, clear_str
    mov si, buffer
    call cmp_word
    jc .not_clear
    call clear_screen
    ret
.not_clear:

    ; Unknown command
    mov si, unknown_msg
    call print_string
    ret

; =======================
; Compare buffer with DI = string (zero-terminated)
; ZF=1 if match, CF=0 if match (for jc/jz logic)
cmp_word:
    push si
    push di
.cmp_loop:
    mov al, [si]
    mov bl, [di]
    or bl, 0
    jz .done
    cmp al, bl
    jne .fail
    inc si
    inc di
    jmp .cmp_loop
.done:
    mov al, [si]
    cmp al, 0x0D    ; Enter or zero
    je .match
    cmp al, ' '
    je .match
    cmp al, 0
    je .match
.fail:
    pop di
    pop si
    stc
    ret
.match:
    pop di
    pop si
    clc
    ret

; =======================
; DATA SECTION
welcome_msg   db 13,10,"YASHXOXO KERNEL",13,10,0
prompt        db "> ",0
help_str      db "help",0
about_str     db "about",0
clear_str     db "clear",0
help_msg      db "Available commands: help, about, clear",13,10,0
about_msg     db "Custom kernel by YASHXOXO!",13,10,0
unknown_msg   db "Unknown command",13,10,0
buffer        times 80 db 0

; =======================
; Boot signature
times 510-($-$$) db 0
dw 0xAA55