# bash exec.shで権限無視して実行可能 

#!/bin/bash
set -e  # エラーが出たら即終了

clear
# コンパイル
cd boot # nasm -f bin ​boot/fat16_init.asm -o fat16_init.binがなぜか実行できない為苦肉の策
nasm -f bin mbr.asm -o mbr.bin
nasm -f bin vbr.asm -o vbr.bin
nasm -f bin ​fat16_init.asm -o fat16_init.bin
cd ..
nasm -f bin kernel.asm -o kernel.bin



# 1GBの仮想HDD生成
dd if=/dev/zero of=virtual_disk.img bs=1M count=1024 

# MBRを先頭512バイトへ書き込み
dd if=boot/mbr.bin of=virtual_disk.img bs=512 count=1 conv=notrunc

# VBRを63セクタ目へ書き込み「第1パーティションの先頭512バイト」
dd if=boot/vbr.bin of=virtual_disk.img bs=512 seek=63 conv=notrunc

# ルートディレクトリ及びFAT表を64バイト目〜「第1パーティションの2セクタ目」に書き込み
dd if=boot/fat16_init.bin of=virtual_disk.img bs=512 seek=64 conv=notrunc

# カーネル部分
dd if=kernel.bin of=virtual_disk.img bs=512 seek=112 conv=notrunc

# 一時ファイル削除
rm -f boot/mbr.bin
rm -f boot/vbr.bin
rm -f boot/fat16_init.bin
rm -f kernel.bin

# 起動する
qemu-system-i386 -hda virtual_disk.img -monitor stdio

  

