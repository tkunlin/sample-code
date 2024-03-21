
FILENAME=$1
/usr/local/bin/aws ecs register-task-definition --cli-input-json file://$FILENAME