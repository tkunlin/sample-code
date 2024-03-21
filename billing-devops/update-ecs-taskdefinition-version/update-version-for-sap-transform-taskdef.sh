#!/usr/bin/env bash

### Description: Get the latest version of AWS ECS task definition and update SSM parameter.
### Create by Richrad.Tsai 2023-12-19

### Fail fast
set -Eeuo pipefail

envval=$1
# Uppercase first char
envval2=${envval^}

echo $envval
echo $envval2


# Get the latest version and AWS ECS task definition via AWSCLI, jq and Linux cut command.
#VERSION=`/usr/local/bin/aws ecs describe-task-definition --task-definition billing-$envval-sap-transform-taskdef | jq --raw-output  ".taskDefinition.taskDefinitionArn" | cut -d : -f 7`
PARAMETER=`/usr/local/bin/aws ecs describe-task-definition --task-definition billing-$envval-sap-transform-taskdef | jq --raw-output  ".taskDefinition.taskDefinitionArn" | cut -d / -f 2`

# Update version of task definition for parameter store
/usr/local/bin/aws ssm put-parameter --name "/$envval2/SapTransform/Connections/TaskDefinition" --type "String" --value "$PARAMETER" --overwrite