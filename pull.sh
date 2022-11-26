#!/bin/sh
cd $1
for file in `ls ./`
do
echo "**************************************************************"
if [ -d "$file" ]
then
  echo "开始 拉取 $file 工程"
  cd $file
  git pull
  echo "$file 工程拉取完成"
  cd ../
elif [ -f "$file" ]
then
  echo "$file 是一个文件，跳过"
fi
echo ""
echo ""
done

