

aws cloudformation deploy --template-file pipeline/pipeline.yaml \
    --stack-name whitelist-pipeline \
    --capabilities CAPABILITY_NAMED_IAM