#!/bin/bash

### Need to re-factor, there are some issues on this scripts Richard Tsai 2024-01-16 


DATA_current=`date +%Y-%m-%d`
WORK_DIR=$PWD
TARGETFODLER="/opt/billing_crontab/"
FODLERNAME=$1
DESTINATION="$TARGETFODLER/$1"
### Check if a directory doesn't  exists, and created.

if [ ! -d "$DESTINATION" ]; then
  mkdir -p $DESTINATION
fi

# Backup old folder and copy all files to DESTINATION folder as a function
copy_file()
{
  #cp -r $DESTINATION/* $DESTINATION-${DATA_current}/
  #rm -rf $DESTINATION/*
  cp ./db_export_hana.sh $DESTINATION/
  cp ./db_restore_hana.sh $DESTINATION/
  cp ./de_id.sql $DESTINATION/
  cp ./insert-into-rd-qa-account.sql $DESTINATION/
  cp ./README.md $DESTINATION/
  cp ./version.txt $DESTINATION/
}

company_type=$2
if [[ ("$1" != "") && ("$compnay_type" == "") ]]
  then
    copy_file

elif [[ ("$1" != "") && ("$company_type" == "ecv") ]]
  then
    copy_file
    sudo cp -f ./db_export_hana_ecv.cron /etc/cron.d/
    echo "Setting ecv cron job"

elif [[ ("$1" != "")  && ("$company_type" == "ecr") ]]
  then
    copy_file
    sudo cp -f ./db_export_hana_ecr.cron /etc/cron.d/
    echo "Setting ecv cron job"

else
    echo "Compnay type error !!  "ecv" or "ecr" only "
fi

sudo chown -R ec2-user:wheel $DESTINATION/
sudo chmod -R 775 $DESTINATION/