For Dev:
aws ecs register-task-definition --cli-input-json file://./billing_dev_cur_etl_pipeline_rebilling_etl_td-revision36-AWS-CLI-input.json

For Uat:
step 2: 註冊 Linux 任務定義

aws ecs register-task-definition --cli-input-json file://./billing_uat_cur_etl_pipeline_rebilling_etl_td-revision36-AWS-CLI-input.json

步驟 3：列出任務定義

aws ecs list-task-definitions | grep billing_uat_cur_etl_pipeline_rebilling_etl_td

參考文件
https://docs.aws.amazon.com/zh_tw/AmazonECS/latest/userguide/ECS_AWSCLI_Fargate.html

Note:

- ECR -- billing_c8uat_revenue_transfer_job_step_function.json doesn't need, due to ECR no company transfer feature.
