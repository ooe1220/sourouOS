# bash exec.shで権限無視して実行可能 

# ===== 定数 =====
VIRTUAL_DISK="virtual_disk.img" #仮想HDD名
PARTITION1_START_SECTOR=63      #パーティション開始セクタ
RESERVED_SECTOR_COUNT=1         #予約セクタ(ここではVBRの大きさ)
SECTORS_PER_FAT=8               #FAT表大きさ
ROOT_DIR_ENTRIES=512            #ルートディレクトリに登録可能なファイル数

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

# 仮想HDD生成128MB
dd if=/dev/zero of=$VIRTUAL_DISK bs=1M count=128

# MBRを先頭512バイトへ書き込み
dd if=boot/mbr.bin of=$VIRTUAL_DISK bs=512 count=1 conv=notrunc

# VBR書き込み
# 第1パーティションの先頭512バイト
dd if=boot/vbr.bin of=$VIRTUAL_DISK bs=512 seek=$PARTITION1_START_SECTOR conv=notrunc

# ルートディレクトリ及びFAT表書き込み
# VBR+予約セクタ 
dd if=boot/fat16_init.bin of=$VIRTUAL_DISK bs=512 seek=$((PARTITION1_START_SECTOR + RESERVED_SECTOR_COUNT)) conv=notrunc

# カーネル部分
dd if=kernel.bin of=$VIRTUAL_DISK bs=512 seek=$((PARTITION1_START_SECTOR + RESERVED_SECTOR_COUNT + SECTORS_PER_FAT * 2 + ROOT_DIR_ENTRIES*32/512)) conv=notrunc

# 検証用ファイル
# データ領域はLBA112〜　63 + 1 + 16(FAT×2) + 32(ルートディレクトリ)
# カーネルが64KBで128セクタ
dd if=testfile/TEST1.TXT of=$VIRTUAL_DISK bs=512 seek=240 count=1 conv=notrunc
 
# COM
cd com
nasm -f bin hello.asm -o hello.com
cd ..
dd if=com/hello.com of=$VIRTUAL_DISK bs=512 seek=248 count=1 conv=notrunc

# 一時ファイル削除
rm -f boot/mbr.bin
rm -f boot/vbr.bin
rm -f boot/fat16_init.bin
rm -f kernel.bin
rm -f com/hello.com

# 起動する
qemu-system-i386 -hda $VIRTUAL_DISK -monitor stdio

  

