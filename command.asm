; 命令解析関数
parse_command:
    pusha
    
    ; 小文字→大文字変換(大文字小文字による差異を無くして後ろの文字列比較処理を簡単にする)
    mov si, input_buffer
    call to_upper
    
    ; 空でないか
    cmp byte [si], 0
    je .empty
   
    ; 命令毎に処理(それぞれの命令と入力を比較して一致すれば実行)

    ; help実行
    ; mov di, cmd_help
    ; call strcmp
    ; je .do_help
    mov si, input_buffer
    mov di, cmd_help
    call strcmp
    cmp ax, 0
    je .do_help

    ; reboot実行
    mov di, cmd_reboot
    call strcmp
    je .do_reboot
    
    ; clear実行
    mov di,cmd_clear
    call strcmp
    je .do_clear
    
    ; 未定義命令
    mov si, unknown_cmd
    call print_string
    jmp .done
    
.do_help:
    mov si, help_text
    call print_string
    jmp .done
    
.do_reboot:
    ;int 0x19
    ;VBRは上書きしていないので再実行するだけの簡単な処理にした
    ;後からもっと細かい処理を実装する予定
    call screen_clear
    jmp 0x0000:0x7C00
    
.do_clear:
    call screen_clear
    jmp .done
    
.empty:
.done:
    popa
    ret

; データ置き場
cmd_dir db 'DIR', 0
cmd_help db 'HELP', 0
cmd_reboot db 'REBOOT', 0
cmd_clear db 'CLEAR', 0
teststr db "test", 0x0D, 0x0A, 0
teststr2 db "test2", 0x0D, 0x0A, 0
    
unknown_cmd db 'Unknown command', 0x0D, 0x0A, 0

help_text db 'Available commands:', 0x0D, 0x0A
          db 'DIR    - Show files', 0x0D, 0x0A
          db 'HELP   - This help', 0x0D, 0x0A
          db 'REBOOT - Restart system', 0x0D, 0x0A, 0
