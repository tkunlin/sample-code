#!/usr/bin/env bash

### Description: The script get the sql file from S3 bucket (billing-db-sql) restore to the dev environment.
### Create by Richrad.Tsai 2023-03-06
### 2023-10-19

### Fail fast
set -Eeuo pipefail

### Get the location
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

PROGRAM=$(basename $0)

VERSION=`cat ./version.txt`
# echo $VERSION

ARGS=$(getopt -o vh --long help,version,deid:,nobillitem:,date:,envent:,dbname:,restorefrom:,poweroff:,permission: -- "$@" )

### Run command without parameter, display command usage
if [[ $? -gt 0 ]]; then
  usage
fi

eval set -- ${ARGS}

usage () {
  echo "
  Usage: $PROGRAM [options]

  Options:

    --help           output usage information
    --version        output the version number
    --deid           does need de-id for db restore (y/n)
    --nobillitem     does need bill-item for db restore (y/n)
    --date           the date of db file, example: 2023-10-19
    --envent         which evnironemnt do you want, example: Dev / Uat / Stage
    --dbname         the database name for db restore
    --restorefrom    db restore from which organization, example: ECV / ECR
    --poweroff       shutdown ec2 instance after restoring db (y/n)
    --permission     assign permission data into database (y/n)
  "
}

while true; do
  case "$1" in
    --deid) DEID=$2;                 shift 2 ;;
    --nobillitem) NOBILLITEM=$2;     shift 2 ;;
    --date) DATE=$2;                 shift 2 ;;
    --envent) ENVTYPE=$2;            shift 2 ;;
    --dbname) DBNAME=$2;             shift 2 ;;
    --restorefrom) RESTOREFROM=$2;   shift 2 ;;
    --poweroff) POWEROFF=$2;         shift 2 ;;
    --permission) PERMISSION=$2;     shift 2 ;;
    -v|--version) echo $VERSION;     break ;;
    -h|--help)  usage;               break ;;
    *) shift;                        break ;;
  esac
done


dump_file_to_db()
{

  ### Run the command start time
  START_TIME=`date +"%Y-%m-%d %T"`
  echo "Start time: $START_TIME"

  envtype=$4

  ### Those parameters get from parameter store, and the need third party package (AWSCLI  and jq)
  HOST=$(/usr/local/bin/aws ssm get-parameter --name "/$envtype/Billing/DB/mysql-endpoint" --region us-west-2 | jq --raw-output ".Parameter.Value")
  USER=$(/usr/local/bin/aws ssm get-parameter --name "/$envtype/Billing/DB/mysql-user" --region us-west-2 | jq --raw-output ".Parameter.Value")
  PASSWORD=$(/usr/local/bin/aws ssm get-parameter --name "/$envtype/Billing/DB/mysql-password" --region us-west-2 | jq --raw-output ".Parameter.Value")
 
  echo "Restoring data into $HOST"
  
  ### To determin which s3 bucket will use
  company_type=$1

  if [ $company_type == "ECV" ]
  then
    s3_bucket_name="billing-db-sql"

  elif [ $company_type == "ECR" ]
  then
    s3_bucket_name="billing-db-sql-c8"

  else
    echo "Compnay type error !!  "ECV" or "ECR" only "

  fi

  ### To determin which db file will use
  no_bill_item=$2

  if [ $no_bill_item == "y" ]
  then
    db_file_name="init_maindb_hana_"$DATE"_no_bill_item.sql"

  elif [ $no_bill_item == "n" ]
  then
    db_file_name="init_maindb_hana_"$DATE".sql"

  else
    echo " File name must specify no_bill_item flag !!  "y" or "n" only "

  fi


  ### copy correct file from correct AWS bucket
  /usr/local/bin/aws s3 cp s3://$s3_bucket_name/db-backup/$db_file_name ./


  ### Restore database file to specify database name
  echo "Restoring $db_file_name to $DBNAME"
  /usr/bin/mysql -h $HOST -u $USER -p$PASSWORD $DBNAME <  ./$db_file_name

  
  ### After restore databse, if need to de-id database, run thie section
  de_id=$3

  if [ $de_id == "y" ]
  then
    echo "de-identification database step"
    /usr/bin/mysql -h $HOST -u $USER -p$PASSWORD $DBNAME <  ./de_id.sql
  else
    echo "Keep the data of original database, no any action!"
  fi


  ### Added RD / QA / Others member permissions, need to remove this. 
  permission=$6

  if [ $permission == "y" ]
  then
    echo "Inserting permission data into database..."
    /usr/bin/mysql -h $HOST -u $USER -p$PASSWORD $DBNAME <  ./insert-into-rd-qa-account.sql
  else
    echo "No insert permission data into database!"
  fi


  ### Run the command stop time
  FINISH_TIME=`date +"%Y-%m-%d %T"`
  echo "Finish time: $FINISH_TIME"

  rm $db_file_name

  power_off=$5

  if [ $power_off == "y" ]
  then
    echo "Going to shutdown in 30 seconds"
    sleep 30
    /usr/bin/sudo /sbin/shutdown -h now
  else
    echo "Keep the ec2 instnace running!"
  fi
}


### To determin which environment will use and run the command.


### To determin which environment will use and run the command.
while :; do
  ### For ECV-Dev
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y" || "n") && ("$ENVTYPE" == "Dev") && ("$POWEROFF" == "y") && ("$PERMISSION" == "y") ]]; then
    echo "condition 1 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM y $ENVTYPE $POWEROFF $PERMISSION 
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y" || "n") && ("$ENVTYPE" == "Dev") && ("$POWEROFF" == "y") && ("$PERMISSION" == "y") ]]; then
    echo "condition 2 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM y $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y" || "n") && ("$ENVTYPE" == "Dev") && ("$POWEROFF" == "n") && ("$PERMISSION" == "y") ]]; then
    echo "condition 3 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM y $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y" || "n") && ("$ENVTYPE" == "Dev") && ("$POWEROFF" == "n") && ("$PERMISSION" == "y") ]]; then
    echo "condition 4 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM y $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y" || "n") && ("$ENVTYPE" == "Dev") && ("$POWEROFF" == "y") && ("$PERMISSION" == "n") ]]; then
    echo "condition 5 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM y $ENVTYPE $POWEROFF $PERMISSION 
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y" || "n") && ("$ENVTYPE" == "Dev") && ("$POWEROFF" == "y") && ("$PERMISSION" == "n") ]]; then
    echo "condition 6 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM y $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y" || "n") && ("$ENVTYPE" == "Dev") && ("$POWEROFF" == "n") && ("$PERMISSION" == "n") ]]; then
    echo "condition 7 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM y $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y" || "n") && ("$ENVTYPE" == "Dev") && ("$POWEROFF" == "n") && ("$PERMISSION" == "n") ]]; then
    echo "condition 8 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM y $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  
  ### For ECV (Uat / Stage)
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "y") ]]; then
    echo "condition 9 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "y") ]]; then
    echo "condition 10 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "y") ]]; then
    echo "condition 11 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "y") ]]; then
    echo "condition 12 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "y") ]]; then
    echo "condition 13 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "y") ]]; then
    echo "condition 14 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "y") ]]; then
    echo "condition 15 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "y") ]]; then
    echo "condition 16 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "n") ]]; then
    echo "condition 17 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "n") ]]; then
    echo "condition 18 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "n") ]]; then
    echo "condition 19 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "n") ]]; then
    echo "condition 20 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "n") ]]; then
    echo "condition 21 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "y") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "n") ]]; then
    echo "condition 22 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "n") ]]; then
    echo "condition 23 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECV")  && ("$NOBILLITEM" == "n") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "n") ]]; then
    echo "condition 24 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;



  ### For ECR (Uat / Stage)
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "y") ]]; then
    echo "condition 25 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "y") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "y") ]]; then
    echo "condition 26 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "y") ]]; then
    echo "condition 27 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "n") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "y") ]]; then
    echo "condition 28-- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "y") ]]; then
    echo "condition 29 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "y") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "y") ]]; then
    echo "condition 30 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "y") ]]; then
    echo "condition 31 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "n") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "y") ]]; then
    echo "condition 32 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;

  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "n") ]]; then
    echo "condition 33 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "y") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "n") ]]; then
    echo "condition 34 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "n") ]]; then
    echo "condition 35 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "n") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "y") && ("$PERMISSION" == "n") ]]; then
    echo "condition 36 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "y") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "n") ]]; then
    echo "condition 37 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "y") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "n") ]]; then
    echo "condition 38 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "n") && ("$DEID" == "y") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "n") ]]; then
    echo "condition 39 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;
  if [[ ("$RESTOREFROM" == "ECR")  && ("$NOBILLITEM" == "n") && ("$DEID" == "n") && ("$ENVTYPE" == "Uat" || "Stage")  && ("$POWEROFF" == "n") && ("$PERMISSION" == "n") ]]; then
    echo "condition 40 -- NOBILLITEM: $NOBILLITEM DEID: $DEID  $ENVTYPE POWEROFF: $POWEROFF PERMISSION: $PERMISSION";
    dump_file_to_db $RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF $PERMISSION
    break; fi;

  echo "$RESTOREFROM $NOBILLITEM $DEID $ENVTYPE $POWEROFF"
  echo "Parameter invalid !!";break;
done
