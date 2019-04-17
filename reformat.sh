#!/usr/bin/env bash

files=(build.sh util.sh)
for file in ${files[@]}
do
    for num_indents in $(seq 10 -1 1)
    do
        sub_pattern=""
        for i in $(seq ${num_indents})
        do
            sub_pattern="${sub_pattern}  "
        done
        sed -E -i.bak 's/^('"${sub_pattern}"')([^[:space:]])/\1\1\2/' ${file}
    done
done
