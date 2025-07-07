; FAT表及びルートディレクトリを0x0000:9000へ読み込む

read_fat:
    pusha
    push es
    
    mov dx, 0x0000      ; 保存先セグメント
    mov bx, 0x9000      ; 保存先オフセット
    mov cx, 0x0000      ; LBA上位16bit (64は下位部分だけ)
    mov si, 0x0040      ; LBA下位16bit (64 = 0x0040)
    mov al, 48          ; 読み込むセクタ数

    call read_sectors
    
    mov si, msg_fat_loaded
    call print_string
    
    pop es
    popa
    
    ret
    
msg_fat_loaded db '[Kernel] FAT info loaded at 0x0000:0x9000', 0x0D, 0x0A, 0

