# Multi-Account Pipeline

A pipeline that leverage the aws codesuite to deploy templates in multiple accounts.


## Table of Contents
- [Basics](#Basics)
- [Installation](#installation)
- [Usage](#usage)
- [Issues](#Issues)
- [Support](#support)


## Basics
```sh
whitelist-pipeline
|--> deploy
|       |----> deploy_templates.sh <-- Used for deploying the templates
|--> pipeline
|       |----> pipeline-deploy.sh  <-- Used to deploy the pipeline.yaml file
|       |----> pipeline.yaml       <-- cfn source for pipeline pipeline
|--> templates
|       |----> multi-account.yaml <-- The templates that the deploy_templates.sh leverages
|--> validation
|       |----> validate_template.sh < -- just some basic validation script for codebuild stage
|--> buildspec.yml <-- Leveraged by codebuild to launch pipeline
|--> README.md     <-- the instructions 

```
## Installation

Download the project source code via git

```sh
git clone https://github.com/getsec/aws-multi-account-pipeline
cd whitelist-source
```

Push the code to an aws codecommit repo of your choice

```sh
git push <your repo>
```

Edit any of the parameters in the pipline/pipeline.yaml file, ensure you have the correct repo (the one you created)

Once you made your changes, run the deploy/deploy_template.sh script.
```sh
bash deploy/deploy_templates.sh
```
Ensure the pipeline deploys succesfully and now any time you make changes to the template/multi-account.yaml file, and push them to master, the pipeline will automatically push these changes after validation.

## Usage

- Create a new branch and push your changes
```sh
git checkout -b 'my-changes'
    (make some changes)
```

- Make a change - lets say you want to add a new IAM Polcy
```yaml
# Replace <SERVICE_NAME> with your service, for naming sake.
Resources:
    <SERVICE_NAME>WhitelistPolicy:
        Type: AWS::IAM::Policy
        Properties:
        PolicyName: !Sub <SERVICE_NAME>-${AWS::StackName}
        Roles:
            - !Ref RoleNameParam
        PolicyDocument:
            Version: "2012-10-17"
            Statement:
            - Effect: "Allow"
                Action:
                - "s3:GetObject"
                - "s3:DeleteObject"
                Resource: 
                    - !Sub arn:aws:s3:*:${AWS::AccountId}:*/*
                    - !Sub arn:aws:s3:*:${AWS::AccountId}:*
```


- Save your code and validate your changes locally.

```sh
## We will ignore the warning checks, because code pipeline doesnt like non-zero returns
cfn-lint --ignore-checks W2 --template templates/whitelist-policies.yaml
 .
 .
 .
<There should be no response>
```

- Push your changes upstream

```sh
git add <filename>
git commit -m 'my comments'
git push
```

-  At this point you can merge this branch with the master branch and the pipeline will deploy
## Issues

My pipeline isn't automatically starting after pushing code?
- Ensure you merged the code from your source branch to the master branch.
- Ensure code pipeline is still looking at the master branch 

My changes were accepted, however validation failed?
- This could have been fixed if we ran cfn-lint before we commited, it would tell us what the issue is right away. [Usage](#usage)

My changes were accepted, validated, approved, but they fail on the final code build step.
- There are a few posible answers for this every one requires you to inspect the build logs
    - Analyze the logs and take a look at the errors
        - Based on the error take the appropriate action, or google the error.
        - Worst comes to worse, if you cant deploy the template in a certain account do to an error, but it works locally, just connect to that account and remove that template, then redeploy the pipeline.
## Support

This pipeline runs on codebuild, with only a shell script that assumes roles into each account through this file
```sh
deploy/deploy_template.sh
```

When you run the pipeline you should be able to see all the logs in CodeBuild and troubleshoot from there. 

If you are still having issues, please reach out to either

- [Open up an issue...](https://github.com/getsec/aws-multi-account-pipeline/issues/new)

