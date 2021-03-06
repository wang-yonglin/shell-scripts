#!/bin/sh
# From Gerrit Code Review 3.2.2
# From Gerrit Code Review 3.2.2
#
# Part of Gerrit Code Review (https://www.gerritcodereview.com/)
#
# Copyright (C) 2009 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# avoid [[ which is not POSIX sh.

commit_check_reg="^(feat|fix|other){1}(\(.*\))?[:：]+(.){2,100}\[(http://|https://)(jira|zhishiku)\.genjiedian\.com/.+\].*$"
commit_message=`cat $1`

commit_check_result=`echo $commit_message | egrep "$commit_check_reg"`

#echo "commit_check_reg:" $commit_check_reg
#echo "commit_file_url:" $commit_file_url
#echo "commit_message:" $commit_message
#echo "commit_check_result:" $commit_check_result


if [ "$commit_check_result" == "" ];then
  echo ""
  echo " *************************不符合提交规范*****************************"
  echo " *                                                                  *"
  echo " * 【规范格式】                                                     *"
  echo " *   提交类型: 提交说明 [相关链接]                                  *"
  echo " *                                                                  *"
  echo " * 【提交示例】                                                     *"
  echo " *  feat: 添加xxx特性 [https://jira.genjiedian.com/EC0001]            *"
  echo " *                                                                  *"
  echo " * 【规范说明】                                                     *"
  echo " *  提交类型(必须)：用于说明提交类型，可选值有以下几种              *"
  echo " *     feat(新增功能)                                               *"
  echo " *     fix(修改bug)                                                 *"
  echo " *     other(依赖、构建、CI、格式等，可通过提交信息说明)            *"
  echo " *  提交说明 (必须)：描述此次提交所修改的内容                       *"
  echo " *  相关链接 (必须)：Jira 链接或 Confluence 链接                    *"
  echo " *                                                                  *"
  echo " ********************************************************************"
exit 1
fi


#==========================================================================#
if test "$#" != 1 ; then
  echo "$0 requires an argument."
  exit 1
fi

if test ! -f "$1" ; then
  echo "file does not exist: $1"
  exit 1
fi

# Do not create a change id if requested
if test "false" = "`git config --bool --get gerrit.createChangeId`" ; then
  exit 0
fi

# $RANDOM will be undefined if not using bash, so don't use set -u
random=$( (whoami ; hostname ; date; cat $1 ; echo $RANDOM) | git hash-object --stdin)
dest="$1.tmp.${random}"

trap 'rm -f "${dest}"' EXIT

if ! git stripspace --strip-comments < "$1" > "${dest}" ; then
   echo "cannot strip comments from $1"
   exit 1
fi

if test ! -s "${dest}" ; then
  echo "file is empty: $1"
  exit 1
fi

# Avoid the --in-place option which only appeared in Git 2.8
# Avoid the --if-exists option which only appeared in Git 2.15
if ! git -c trailer.ifexists=doNothing interpret-trailers \
      --trailer "Change-Id: I${random}" < "$1" > "${dest}" ; then
  echo "cannot insert change-id line in $1"
  exit 1
fi

if ! mv "${dest}" "$1" ; then
  echo "cannot mv ${dest} to $1"
  exit 1
fi
