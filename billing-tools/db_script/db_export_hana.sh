#!/bin/bash

### This script will dump prod db to s3://billing-db-sql/db-backup/
### 2023-05-02 Created by Richard.Tsai 
### 2023-09-06 Added new parameter for backup month by Richard Tsai
### 2024-01-16 Added new tables for backup every by Richard Tsai

### Fail fast
set -Eeuo pipefail

### Run the command start time
START_TIME=`date +"%Y-%m-%d %T"`
echo "Start time: $START_TIME"


### Use company type to get different parameter
company_type=$1
env_type=$2

if [ $company_type == "ecv" ]
  then
    HOST=$(/usr/local/bin/aws ssm get-parameter --name "/$env_type/Billing/DB/mysql-replica-endpoint" --region us-west-2 | jq --raw-output ".Parameter.Value")
    db_backet="billing-db-sql"
    echo "ECV-Prod"
    echo "================" 
    echo "DB endpoint: $HOST"
    echo "s3 bucket: $db_backet"

elif [ $company_type == "ecr" ]
  then
    HOST=$(/usr/local/bin/aws ssm get-parameter --name "/$env_type/Billing/DB/mysql-endpoint" --region us-west-2 | jq --raw-output ".Parameter.Value")
    db_backet="billing-db-sql-c8"
    echo "ECR-Prod"
    echo "================" 
    echo "DB endpoint: $HOST"
    echo "s3 bucket: $db_backet"

else
  echo "Compnay type error !!  "ecv" or "ecr" only "

fi


### Those parameters get from parameter store, and the need third party package (AWSCLI  and jq)
USER=$(/usr/local/bin/aws ssm get-parameter --name "/$env_type/Billing/DB/mysql-user" --region us-west-2 | jq --raw-output ".Parameter.Value")
PASSWORD=$(/usr/local/bin/aws ssm get-parameter --name "/$env_type/Billing/DB/mysql-password" --region us-west-2 | jq --raw-output ".Parameter.Value")


### Set $3 (parameter 3 ), to chagne the backup month Richard Tsai, 2023-08-14
BACKUP_MONTH=$3
DATE_current=`date +%Y-%m-%d`
DATE=`date -d "$BACKUP_MONTH month ago" '+%Y/%m'`
echo "Backup Month is $DATE"

WORK_DIR='/opt/billing_crontab/db_backup'


### Added bill_awscontract_info, bill_awscontract_payer, bill_awscontract_info, bill_savingplan_list by Richard Tsai, 2023-07-11
/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud bill_customer bill_customer_si bill_cdn bill_price1 bill_product bill_payer_account bill_region ri_instance_base_type bill_price_si bill_rate_list bill_master bill_master_customer bill_admin_name bill_admin_power bill_code bill_customer_sap bill_customer_tax bill_digital_tax bill_tax bill_prepaid_customer bill_prepaid_group bill_prepaid_record ecs_pods bill_awscontract_list bill_awscontract_payer bill_awscontract_info bill_savingplan_list  > /tmp/init_no_bill_item.sql

/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud bill_invoice_revenue --where="bill_period >= '$DATE'" >> /tmp/init_no_bill_item.sql

/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud bill_ri_new --where="bill_period >= '$DATE'" >> /tmp/init_no_bill_item.sql

/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud bill_rate --where="bill_period >= '$DATE'" >> /tmp/init_no_bill_item.sql

/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud sp_recommendation --where="bill_period >= '$DATE'" >> /tmp/init_no_bill_item.sql

/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud sp_recommendation_detail --where="spr_id in (select id FROM sp_recommendation where bill_period >= '$DATE')  " --single-transaction >> /tmp/init_no_bill_item.sql

# Backup new tables for daily backup by Richard Tsai, 2024-01-16
/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud per_permission per_role per_role_permission per_role_scope per_user_permission bill_system_user bill_system_role bill_system_menu bill_system_menu_buttons bill_system_dict bill_system_department  >> /tmp/init_no_bill_item.sql


cat /tmp/init_no_bill_item.sql > /tmp/init_maindb.sql

# ---------------------------------------------------------------
/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud bill_item --where="bill_period >= '$DATE'" >> /tmp/init_maindb.sql

/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud bill_monthly_cost_report --where="bill_period >= '$DATE'" >> /tmp/init_maindb.sql

/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud bill_savingplan_list bill_savingplan_pricinglist >> /tmp/init_maindb.sql

/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud bill_item --no-create-info --where="bill_period >= '$DATE' and dop in ('y', 't') and hide='n' " | sed -e "s/([0-9]*,/(NULL,/gi" > /tmp/dop.sql

# sap migration add
/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud migration_bill_close >> /tmp/init_maindb_close.sql

# sap migration add
# Added migration_bill_invoice_no by Richard Tsai 2023-07-11
/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud migration_bill_item_sap migration_bill_item_sap_cost migration_bill_item_settle migration_bill_invoice_settle migration_bill_invoice_no --where="bill_period >= '$DATE'" >> /tmp/init_maindb_close.sql

# sap migration add
/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud migration_report_log >> /tmp/init_maindb_close.sql

# sap migration add
/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud migration_bill_close_verify >> /tmp/init_maindb_close.sql

# sap migration add
/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud migration_bill_item_sap_verify migration_bill_item_sap_cost_verify migration_bill_item_settle_verify migration_bill_invoice_settle_verify --where="bill_period >= '$DATE'" >> /tmp/init_maindb_close.sql

# Backup closed accounts data by Richard Tsai, 2023-07-11
#/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud migration_opor_verify migration_ordr_verify migration_por1_verify migration_rdr1_verify --where="bill_period >= '$DATE'" >> /tmp/init_maindb_close.sql
/usr/bin/mysqldump -h $HOST -u $USER -p$PASSWORD --set-gtid-purged=OFF ecloud migration_opor_verify migration_ordr_verify migration_por1_verify migration_rdr1_verify  >> /tmp/init_maindb_close.sql




cat /tmp/init_maindb_close.sql >> /tmp/init_maindb.sql
cp /tmp/init_maindb.sql /tmp/init_maindb_de_id.sql
cat $WORK_DIR/de_id.sql >> /tmp/init_maindb_de_id.sql


if [ ${BACKUP_MONTH} == "1" ]
  then
    /usr/local/bin/aws s3 cp /tmp/init_no_bill_item.sql s3://$db_backet/db-backup/init_maindb_hana_${DATE_current}_no_bill_item.sql
    /usr/local/bin/aws s3 cp /tmp/init_maindb.sql s3://$db_backet/db-backup/init_maindb_hana_${DATE_current}.sql
    /usr/local/bin/aws s3 cp /tmp/dop.sql s3://$db_backet/db-backup/init_maindb_hana_${DATE_current}_dop.sql
    /usr/local/bin/aws s3 cp /tmp/init_maindb_de_id.sql s3://$db_backet/db-backup/init_maindb_hana_${DATE_current}_de_id.sql

elif [ ${BACKUP_MONTH} == "3" ]
  then
    /usr/local/bin/aws s3 cp /tmp/init_no_bill_item.sql s3://$db_backet/db-backup/init_maindb_hana_${DATE_current}_no_bill_item_${BACKUP_MONTH}month.sql
    /usr/local/bin/aws s3 cp /tmp/init_maindb.sql s3://$db_backet/db-backup/init_maindb_hana_${DATE_current}_${BACKUP_MONTH}month.sql
    /usr/local/bin/aws s3 cp /tmp/dop.sql s3://$db_backet/db-backup/init_maindb_hana_${DATE_current}_dop_${BACKUP_MONTH}month.sql
    /usr/local/bin/aws s3 cp /tmp/init_maindb_de_id.sql s3://$db_backet/db-backup/init_maindb_hana_${DATE_current}_de_id_${BACKUP_MONTH}month.sql
else
  echo "The backup month is invalid !! 1 month or 3 months only "

fi

#aws s3 cp /tmp/init_maindb.sql s3://ecv-us-west-2-dev/db-backup/init_maindb.sql
rm /tmp/init_no_bill_item.sql
rm /tmp/init_maindb.sql
rm /tmp/dop.sql
rm /tmp/init_maindb_close.sql
rm /tmp/init_maindb_de_id.sql

### Run the command stop time
FINISH_TIME=`date +"%Y-%m-%d %T"`
echo "Finish time: $FINISH_TIME"