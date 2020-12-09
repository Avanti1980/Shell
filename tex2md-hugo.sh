SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

doc_start=0        # 是否开始正文
align_start=0      # 是否开始段落
itemize_start=0    # 是否开始无序列表
enumerate_start=0  # 是否开始有序列表
enumerate_number=0 # 有序列表计数器
thm_start=0        # 是否开始定理
defn_start=0       # 是否开始定义
alg_start=0        # 是否开始算法

file=$(echo $1 | sed 's/\(.*\)\.tex/\1/g') # $1是tex文件路径 去掉.tex 获取路径+文件名

if [ -f "$file.md" ]; then
  rm $file.md # 如果有对应的md文件 删除之
fi

while read -r line; do # 一行一行处理

  if [ $doc_start == 1 ]; then # 正文开始

    if [ -z "$last_line" ]; then                             # 上一行为空
      if [[ $line =~ "\section" ]]; then                     # 当前行是标题
        title=$(echo $line | sed 's/\\section{\(.*\)}/\1/g') # 获取{}里的部分
        title=$(echo $title | sed 's/~~/ /g')                # 将latex里的~~转成空格
        line="## $title"
      elif [[ $line =~ "\subsection" ]]; then # 当前行是次标题
        title=$(echo $line | sed 's/\\subsection{\(.*\)}/\1/g')
        title=$(echo $title | sed 's/~~/ /g')
        line="#### $title"
      elif [[ $line =~ "\subsubsection" ]]; then # 当前行是次次标题
        title=$(echo $line | sed 's/\\subsubsection{\(.*\)}/\1/g')
        title=$(echo $title | sed 's/~~/ /g')
        line="###### $title"
      else # 当前行是段落开始
        line="　　$line"
      fi
    fi

    if [[ $line =~ "\begin{align" ]]; then # align环境开始
      line="\$\$ ${line}"                  # align* -> align\*
      align_start=1
    elif [[ $line =~ "\end{align" ]]; then # align环境结束
      line="${line} \$\$"
      align_start=0
    fi

    if [[ $line =~ "\begin{itemize}" ]]; then # itemize环境开始
      itemize_start=1
      continue
    fi

    if [[ $line =~ "\end{itemize}" ]]; then # itemize环境结束
      itemize_start=0
      continue
    fi

    if [[ $line =~ "\begin{enumerate}" ]]; then # enumerate环境开始
      enumerate_start=1
      enumerate_number=0 # 计数清零
      continue
    fi

    if [[ $line =~ "\end{enumerate}" ]]; then # enumerate环境结束
      enumerate_start=0
      continue
    fi

    if [[ $line =~ "\begin{thm}" ]] || [[ $line =~ "\begin{lem}" ]] || [[ $line =~ "\begin{defn}" ]]; then # 定理环境开始 还可以加上lemma cor那些 处理是一样的 以后再说
      thm_start=1
      continue
    fi

    if [[ $line =~ "\end{thm}" ]] || [[ $line =~ "\end{lem}" ]] || [[ $line =~ "\end{defn}" ]]; then # 定理环境结束
      thm_start=0
      continue
    fi

    if [[ $line =~ "\begin{algorithm" ]]; then # algorithm环境开始
      alg_start=1
      enumerate_number=0
      continue
    fi

    if [[ $line =~ "\end{algorithm" ]]; then # algorithm环境结束
      alg_start=0
      continue
    fi

    if [ $alg_start == 1 ]; then
      if [[ $line =~ "\caption" ]]; then # 获取算法的caption
        line=$(echo $line | sed 's/.*\\caption{\([^}]*\)}/> \1/g')
      elif [[ $line =~ "\STATE" ]]; then # 获取算法的步骤
        ((enumerate_number++))
        line=$(echo $line | sed "s/.*\\STATE\(.*\)/> $enumerate_number.\1/g")
      elif [[ $line =~ "\FOR" ]]; then # 获取算法的步骤
        ((enumerate_number++))
        line=$(echo $line | sed "s/.*\\FOR{\(.*\)}/> $enumerate_number. for \1 do/g")
      elif [[ $line =~ "\ENDFOR" ]]; then # 获取算法的步骤
        ((enumerate_number++))
        line=$(echo $line | sed "s/.*\\ENDFOR/> $enumerate_number. end for/g")
      else
        line=">$line" # 不是一个新的步骤
      fi
    fi

    if [ $itemize_start == 1 ]; then
      if [[ $line =~ "\item" ]]; then
        line=$(echo $line | sed 's/.*\\item\(.*\)/-\1/g')
      else
        line="  $line" # 不是一个新的item
      fi
    fi

    if [ $enumerate_start == 1 ]; then
      if [[ $line =~ "\item" ]]; then
        ((enumerate_number++))
        line=$(echo $line | sed "s/.*\\item\(.*\)/$enumerate_number.\1/g")
      else
        line="  $line" # 不是一个新的item
      fi
    fi

    if [ $thm_start == 1 ]; then
      line=$(echo $line | sed "s/[ ]*\(.*\)/> \1/g") # 定理变成markdown的引用
    fi

    line="${line//\\\\/\\\\\\\\}"
    line="${line//\\|/\\\\|}"
    line="${line//\\\{/\\\\\{}"
    line="${line//\\\}/\\\\\}}"
    line="${line//\\textcolor/\\color}"

    if [[ $line =~ "\textbf" ]]; then # 处理\textbf{}中的文本
      line=$(echo $line | sed 's/\\textbf{\([^}]*\)}/**\1**/g')
    fi

    if [[ $line =~ "\end{document}" ]]; then # 正文结束
      doc_start=0
      continue
    fi

    echo "$line" >>$file.md
  fi

  if [[ $last_line =~ "maketitle" ]] && [ -z "$line" ]; then # 当前行为空且上一行为maketitle表示正文开始
    doc_start=1
    last_line=$line
    continue
  fi

  if [[ $line =~ "\end{align" ]]; then # align环境结束
    echo "" >>$file.md
  fi

  last_line=$line

done \
  < \
  $1
