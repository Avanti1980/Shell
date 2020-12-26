#!/usr/bin/env bash

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

doc_start=0        # 是否开始正文
align_start=0      # 是否开始行间公式
itemize_start=0    # 是否开始无序列表
enumerate_start=0  # 是否开始有序列表
enumerate_number=0 # 有序列表计数器
thm_start=0        # 是否开始定理
thm_print=0        # 是否输出定理二字
thm_number=0       # 定理编号
proof_start=0      # 是否开始证明
proof_print=0      # 是否输出证明二字
defn_start=0       # 是否开始定义
alg_start=0        # 是否开始算法
alg_number=0       # 算法编号

file=$(echo $1 | sed 's/\(.*\)\.tex/\1/g') # $1是tex文件路径 去掉.tex 获取路径+文件名

if [ -f "$file.md" ]; then
    rm $file.md # 如果有对应的md文件 删除之
fi

echo "process cross reference" >cr.txt

while read -r line; do # 一行一行处理

    if [ $doc_start == 1 ]; then # 正文开始

        if [ -z "$line" ]; then
            echo $line >>$file.md
            last_line=$line
            continue
        fi

        if [ -z "$last_line" ]; then                                 # 上一行为空
            if [[ $line =~ "\section" ]]; then                       # 当前行是标题
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
            line="${line/\*/\\\*}"             # align* -> align\*
            align_start=1
        elif [[ $line =~ "\end{align" ]]; then # align环境结束
            line="${line/\*/\\\*}"
            align_start=0
        fi

        if [[ $line =~ "\begin{itemize}" ]]; then # itemize环境开始
            itemize_start=1
            last_line=$line
            continue
        elif [[ $line =~ "\end{itemize}" ]]; then # itemize环境结束
            itemize_start=0
            last_line=$line
            continue
        fi

        if [[ $last_line =~ "\end{itemize}" ]] && [ -n "$line" ]; then
            echo "" >>$file.md
        fi

        if [[ $line =~ "\begin{enumerate}" ]]; then # enumerate环境开始
            enumerate_start=1
            enumerate_number=0 # 计数清零
            last_line=$line
            continue
        elif [[ $line =~ "\end{enumerate}" ]]; then # enumerate环境结束
            enumerate_start=0
            last_line=$line
            continue
        fi

        if [[ $line =~ "\begin{theorem}" ]] || [[ $line =~ "\begin{lemma}" ]] || [[ $line =~ "\begin{definition}" ]]; then # 定理环境开始
            thm_start=1
            thm_print=1
            ((thm_number++))
            last_line=$line
            if [[ $line =~ "\label{" ]]; then
                echo $line,$thm_number | sed 's/.*\\label{\(.*\)}/\1/' >>cr.txt
            fi
            continue
        elif [[ $line =~ "\end{theorem}" ]] || [[ $line =~ "\end{lemma}" ]] || [[ $line =~ "\end{definition}" ]]; then # 定理环境结束
            thm_start=0
            last_line=$line
            continue
        fi

        if [[ $line =~ "\begin{proof}" ]]; then # 证明环境开始
            proof_start=1
            proof_print=1
            last_line=$line
            continue
        elif [[ $line =~ "\end{proof}" ]]; then # 证明环境结束
            proof_start=0
            last_line=$line
            continue
        fi

        if [[ $line =~ "\begin{algorithm" ]]; then # algorithm环境开始
            alg_start=1
            enumerate_number=0
            ((alg_number++))
            last_line=$line
            if [[ $line =~ "\label{" ]]; then
                echo $line,$alg_number | sed 's/.*\\label{\(.*\)}/\1/' >>cr.txt
            fi
            continue
        elif [[ $line =~ "\end{algorithm" ]]; then # algorithm环境结束
            alg_start=0
            last_line=$line
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
            line=$(echo $line | sed 's/          //')
            if [[ $line =~ "\item" ]]; then
                line=$(echo $line | sed 's/.*\\item\(.*\)/-\1/')
            fi
        fi

        if [ $enumerate_start == 1 ]; then
            line=$(echo $line | sed 's/          //')
            if [[ $line =~ "\item" ]]; then
                ((enumerate_number++))
                line=$(echo $line | sed "s/.*\\item\(.*\)/$enumerate_number.\1/")
            fi
        fi

        if [ $thm_start == 1 ]; then
            line=$(echo $line | sed 's/    //')
            if [ $thm_print == 1 ]; then
                line=$(echo $line | sed "s/\(.*\)/**定理${thm_number}**：\1/")
                thm_print=0
            fi
        fi

        if [ $proof_start == 1 ]; then
            line=$(echo $line | sed 's/    //')
            if [ $proof_print == 1 ]; then
                line=$(echo $line | sed 's/\(.*\)/**证明**：\1/')
                proof_print=0
            fi
        fi

        if [ $align_start == 1 ]; then
            line="${line//\\\\/\\\\\\\\}"
            line="${line//\\|/\\\\|}"
            line="${line//\\\{/\\\\\{}"
            line="${line//\\\}/\\\\\}}"
            line="${line//_/\\_}"
            line="${line//\\textcolor/\\color}"
            if [ $itemize_start == 1 ]; then
                line=$(echo $line | sed 's/            /    /')
                line=$(echo $line | sed 's/        /    /')
            fi
            line=$(echo $line | sed 's/\\blue{\([^}]*\)}/\\class{blue}{\1}/g')
            line=$(echo $line | sed 's/\\red{\([^}]*\)}/\\class{red}{\1}/g')
            line=$(echo $line | sed 's/\\green{\([^}]*\)}/\\class{green}{\1}/g')
            line=$(echo $line | sed 's/\\yellow{\([^}]*\)}/\\class{yellow}{\1}/g')
            line=$(echo $line | sed 's/\\violet{\([^}]*\)}/\\class{violet}{\1}/g')
        fi

        if [[ $line =~ "\textbf" ]]; then # 处理\textbf{}中的文本
            line=$(echo $line | sed 's/\\textbf{\([^}]*\)}/**\1**/g')
        fi

        if [[ $line =~ "\violet" ]]; then # 处理\violet{}中的文本
            line=$(echo $line | sed 's/\\violet{\([^}]*\)}/<span class="violet"\>\1<\/span\>/g')
        fi

        if [[ $line =~ "\red" ]]; then # 处理\red{}中的文本
            line=$(echo $line | sed 's/\\red{\([^}]*\)}/<span class="red"\>\1<\/span\>/g')
        fi

        if [[ $line =~ "\green" ]]; then # 处理\green{}中的文本
            line=$(echo $line | sed 's/\\green{\([^}]*\)}/<span class="green"\>\1<\/span\>/g')
        fi

        if [[ $line =~ "\blue" ]]; then # 处理\blue{}中的文本
            line=$(echo $line | sed 's/\\blue{\([^}]*\)}/<span class="blue"\>\1<\/span\>/g')
        fi

        if [[ $line =~ "\href" ]]; then # 处理\href{}中的文本
            line=$(echo $line | sed 's/\\href{\([^}]*\)}{\([^}]*\)}/<u>[\2](\1)<\/u>/g')
        fi

        if [[ $line =~ "定理\ref{" ]]; then # 处理定理引用的问题
            label=$(echo $line | sed 's/.*定理\\ref{\([^}]*\).*/\1/')
            number=$(grep "$label" cr.txt | cut -d ',' -f 2)
            line=$(echo $line | sed 's/\\ref{\([^}]*\)}/'$number'/')
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

    last_line=$line

done <$1

rm cr.txt
