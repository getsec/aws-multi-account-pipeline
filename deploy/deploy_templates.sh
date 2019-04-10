templates_dir="templates"
params="$*"
ret=0
# Replace me with the naming convention you want to deploy to.
account_type='xxx'
# Replace me with the cross account role name...
role_name='yyy'

# needed to propogate
set -a
kill_session () {
        unset AWS_ACCESS_KEY_ID
        unset AWS_SESSION_TOKEN
        unset AWS_SECRET_ACCESS_KEY
        echo "Succesfully unset old keys"
        echo ""
}

run_cfn () {
    # wrapper around "aws cloudformation" CLI to ignore certain pseudo-errors

    # aws cloudformation deploy exits with 255 for "No changes to deploy" see: https://github.com/awslabs/serverless-application-model/issues/71
    # this script exits with 0 for that case

    STDERR=$(( aws cloudformation "$@" ) 2>&1)
    ERROR_CODE=$?
    echo ${STDERR} 1>&2
    if [[ "${ERROR_CODE}" -eq "255" && "${STDERR}" =~ "No changes to deploy" ]]; then
        return 0;
    fi
    return ${ERROR_CODE}
}

acct_list=$(aws organizations list-accounts --output table | grep $account_type | awk {'print $6'}) 
acct_list_with_name=$(aws organizations list-accounts --output table | grep $account_type | awk {'print $12"-""("$6")"'})
num_acct=$(echo $acct_list | tr ' ' '\n' | wc -l) 

cd ${templates_dir}


echo "######################################"
echo "# $num_acct Account to deploy to."
for i in $acct_list_with_name; do
    echo "# $i"
    done
echo "######################################"    


for account in $acct_list; do

    for filename in $(find . -name '*.yaml'); do
        
        echo "Deploying $filename into $account"
        echo "Currently assmung role $role_name in account: $account"
        echo ARN: arn:aws:iam::$account:role/$role_name

        x=$(aws sts assume-role --role-arn arn:aws:iam::$account:role/$role_name \
            --role-session-name pipeline_role_$account \
            --output text --query 'Credentials.[AccessKeyId, SecretAccessKey, SessionToken]' )

        if [ "$?" -gt "0" ]; then
            echo "Failed to assume role $role_name in account $account"
            continue
        fi

        AWS_ACCESS_KEY_ID=$(echo $x|awk {'print $1'})
        AWS_SECRET_ACCESS_KEY=$(echo $x|awk {'print $2'})
        AWS_SESSION_TOKEN=$(echo $x|awk {'print $3'})

        
        stack_name=$(echo $filename | sed 's/.yaml//' | sed 's/.\///')
        realname=$(echo $filename | sed 's/.\///')

        run_cfn deploy --template-file $realname --stack-name $stack_name --capabilities CAPABILITY_NAMED_IAM

        if [ "$?" -gt "0" ]; then
            aws cloudformation describe-stack-events --stack-name $stack_name > ../temp/fail
            error=$(cat ../temp/fail  | grep -i Failed -n2  | grep ResourceStatusReason | awk '{sub(/^\S+\s*/,"")}1'  | sort -u)
            
            echo "[FAILURE] Account ID: $account:"
            echo "[FAILURE] Filename:   $filename"
            echo "[FAILURE] Role:       $role"
            echo "[FAILURE] ${filename}: Error: $error"
            ret=1
            exit 1
        else
            echo "[PASS] Succesfully deployed ${filename} in the account $account"
        fi

        kill_session
    done
done

exit ${ret}