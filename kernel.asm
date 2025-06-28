[BITS 16]
[ORG 0x8000]

start:
    ; レジスタ初期化
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    ; スタック設定
    mov ss, ax
    mov sp, 0x7C00
    
    mov si, load_msg
    call print_string
    
    ; FAT表及びルートディレクトリを読み込む
    call read_fat
    
    mov si, title_msg
    call print_string
    
command_loop:
    
    ; c:\>を表示
    mov si, prompt
    call print_string
    
    ;キーボードから入力されるのを待つ(入力が終わるまで返ってこない) int 0x16未使用
    call read_input
    
    ;mov si, newline
    ;call print_string
    
    ;入力された命令によって処理をする
    mov si, input_buffer
    call parse_command
    
    ; command_loopへ戻りc:\>を表示して次の命令を待つ
    jmp command_loop

; 起動画面に表示する文字列
load_msg db "[Kernel] Execution started at 0x0000:0x8000", 0x0D, 0x0A,0

title_msg db "******************************", 0x0D, 0x0A,
        db "*   SOUROU OS Version 1.0    *", 0x0D, 0x0A,
        db "******************************", 0x0D, 0x0A,
        db "", 0x0D, 0x0A,
        db "Operating System is up and running. ", 0x0D, 0x0A,
        db "", 0x0D, 0x0A, 0

prompt db  'C:\>', 0

; 他のソースをこの位置へ展開
%include "driver/keyboard.asm"
%include "driver/vga.asm"
%include "driver/disk.asm"
%include "filesystem/fat16.asm"
%include "command.asm"
%include "strings.asm"

; ここで64KBまで0埋めする
times 65536-($-$$) db 0
