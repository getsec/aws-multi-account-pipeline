#!/bin/bash

# Example: bash githooks/validate-templates.sh --profile mvr


templates_dir="templates"
params="$*"
ret=0

cd ${templates_dir}
for filename in $(find . -name '*.yaml'); do
    cfn-lint --ignore-checks W2 --template ${filename} 
    if [ "$?" -gt "0" ]; then
        echo "[fail] ${filename}"
        ret=1
    else
        echo "[pass] ${filename}"
    fi
done

exit ${ret}