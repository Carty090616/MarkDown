#!/bin/sh
#chkconfig: 2345 80 90
#description:hello.sh

# 打印
echo -e "操作菜单: "
echo -e "\t 1：git pull"
echo -e "\t 2：git add"
echo -e "\t 3：git checkout"
echo -e "\t 4：git merge"
echo -e "\t 5：exit"

# 循环执行
while true
do

	# 用户输入
	read -p "请输入需要执行的操作选项: " number

	# **********   git pull 开始执行   **********
	if [ 1 == ${number} ]
	then
		git pull
	# **********   git pull 结束执行   **********
	
	
	# **********   git add 开始执行   **********
	elif [ 2 == ${number} ]
	then
		echo "++++++++++++++++    pull 开始    ++++++++++++++++"
		git pull
		echo "++++++++++++++++    pull 结束    ++++++++++++++++"
		
		echo "++++++++++++++++    add 开始    ++++++++++++++++"
		git add .
		echo "++++++++++++++++    add 结束    ++++++++++++++++"
		
		echo "++++++++++++++++    commit 开始    ++++++++++++++++"
		read -p "请输入commit操作备注: " remark
		git commit -m ${remark}
		echo "++++++++++++++++    commit 结束    ++++++++++++++++"
		
		echo "++++++++++++++++    push 开始    ++++++++++++++++"
		git push
		echo "++++++++++++++++    push 结束    ++++++++++++++++"
	# **********   git add 结束执行   **********
	
	
	# **********   git checkout 开始执行   **********
	elif [ 3 == ${number} ]
	then
		echo "++++++++++++++++    pull 开始    ++++++++++++++++"
		git pull
		echo "++++++++++++++++    pull 结束    ++++++++++++++++"
		
		echo "++++++++++++++++    checkout 开始    ++++++++++++++++"
		read -p "请输入需要切换的分支名: " checkoutBranch
		git checkout ${checkoutBranch}
		if [ $? -ne 0 ]
		then
			echo $?
		else
			echo $?
		fi
		echo "++++++++++++++++    checkout 结束    ++++++++++++++++"
		
		echo "++++++++++++++++    pull 开始    ++++++++++++++++"
		git pull
		echo "++++++++++++++++    pull 结束    ++++++++++++++++"
	# **********   git checkout 结束执行   **********
	
	
	# **********   git merge 开始执行   **********
	elif [ 4 == ${number} ]
	then
		echo "++++++++++++++++    pull 开始    ++++++++++++++++"
		git pull
		echo "++++++++++++++++    pull 结束    ++++++++++++++++"
		
		echo "++++++++++++++++    checkout 开始    ++++++++++++++++"
		read -p "请输入需要切换的分支名: " branch
		git checkout ${branch}
		echo "++++++++++++++++    checkout 结束    ++++++++++++++++"
		
		echo "++++++++++++++++    pull 开始    ++++++++++++++++"
		git pull
		echo "++++++++++++++++    pull 结束    ++++++++++++++++"
		
		echo "++++++++++++++++    merge 开始    ++++++++++++++++"
		read -p "请输入merge操作备注: " mergeRemark
		read -p "请输入需要合并的分支名: " mergeBranch
		git merge --no-ff -m ${mergeRemark} ${mergeBranch}
		echo "++++++++++++++++    merge 结束    ++++++++++++++++"
		
		echo "++++++++++++++++    push 开始    ++++++++++++++++"
		git push
		echo "++++++++++++++++    push 结束    ++++++++++++++++"
	# **********   git merge 结束执行   **********
	
	
	# **********   exit   **********
	elif [ 5 == ${number} ]
	then
		exit
	# **********   exit   **********
	
	
	# **********   没有识别出的操作   **********
	else
		echo "不存在此选项"
	fi
done