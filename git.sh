#!/bin/sh
#chkconfig: 2345 80 90
#description:hello.sh

# 打印
echo -e "操作菜单: "
echo -e "\t 1：git pull"
echo -e "\t 2：git add"
echo -e "\t 3：git checkout"
echo -e "\t 4：git merge"

# 循环执行
while true
do

	# 用户输入
	read -p "请输入需要执行的操作选项: " number

	# **********   操作一开始执行   **********
	if [ 1 == ${number} ]
	then
		git pull
	# **********   操作一结束执行   **********
	
	
	# **********   操作二开始执行   **********
	elif [ 2 == ${number} ]
	then
		git pull
		echo "++++++++    pull 完    ++++++++"
		
		git add .
		echo "++++++++    add 完    ++++++++"
		
		read -p "请输入提交备注: " remark
		git commit -m ${remark}
		echo "++++++++    commit 完    ++++++++"
		
		git push
		echo "++++++++    push 完    ++++++++"
	# **********   操作二结束执行   **********
	
	
	# **********   操作三开始执行   **********
	elif [ 3 == ${number} ]
	then
		exit
	# **********   操作三结束执行   **********
	
	
	# **********   操作四开始执行   **********
	elif [ 4 == ${number} ]
	then
		exit
	# **********   操作四结束执行   **********
	
	
	# **********   没有识别出的操作   **********
	else
		echo "不存在此选项"
	fi
done