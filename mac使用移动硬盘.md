### Mac读写NTFC格式的硬盘

1. 打开MAC“终端”，输入：  diskutil list   查看当前硬盘的 NAME：如下图

2. 输入:  sudo vim /etc/fstab 文件；

3. 输入:  LABEL=MACNFS none ntfs rw,auto,nobrowse

   + **注意：MACOS 10.12.4 可能没有fstab文件，有fstab.hd文件，不用去管。直接创建一个fstab文件就可以了。**

4. 输入：sudo ln -s /Volumes/MACNFS  ~/Desktop/MACFS 创建桌面快捷方式， 其中 MACNFS是移动硬盘名称，这个是自己之前定义的，  MACFS可以起一个自己喜欢的名字，是后期显示移动硬盘的名称，及挂载的文件夹名称。