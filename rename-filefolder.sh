num=0
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
file_list=$(ls)
for file in $file_list; do
    mv "$file" "$(echo $file | sed 's/\(.*\).ts/\1/g').mp4"
done
