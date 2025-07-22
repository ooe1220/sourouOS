print_ax_hex:
    pusha
    push ds
    push es

    mov dx, ax         ; AXの値を退避（DL=下位, DH=上位）

    ; DI = 0（VRAMオフセット、文字2バイト単位）
    mov di, 0

    ; ES = 0xB800（VRAM）
    mov ax, 0xB800
    mov es, ax

    ; DS = CS（hex_table参照用）
    mov ax, cs
    mov ds, ax

    ; --- DHの上位4bit ---
    mov al, dh
    shr al, 4
    and al, 0x0F
    mov bl, al
    mov bh, 0
    mov al, [hex_table + bx]
    mov [es:di], al
    mov byte [es:di+1], 0xE0
    add di, 2

    ; --- DHの下位4bit ---
    mov al, dh
    and al, 0x0F
    mov bl, al
    mov bh, 0
    mov al, [hex_table + bx]
    mov [es:di], al
    mov byte [es:di+1], 0xE0
    add di, 2

    ; --- DLの上位4bit ---
    mov al, dl
    shr al, 4
    and al, 0x0F
    mov bl, al
    mov bh, 0
    mov al, [hex_table + bx]
    mov [es:di], al
    mov byte [es:di+1], 0xE0
    add di, 2

    ; --- DLの下位4bit ---
    mov al, dl
    and al, 0x0F
    mov bl, al
    mov bh, 0
    mov al, [hex_table + bx]
    mov [es:di], al
    mov byte [es:di+1], 0xE0
    add di, 2

    pop es
    pop ds
    popa
    ret

hex_table:
    db '0123456789ABCDEF'
