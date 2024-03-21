#!/bin/bash

### This script will create billing-tool-db-scripts-vx.x.x.x.tar for deploy 
VERSION=`cat ./version.txt`

echo "$VERSION"

TARGET_FOLDER="billing-tool-db-script-latest"

mkdir -p /tmp/$TARGET_FOLDER
cp -r ./* /tmp/$TARGET_FOLDER

cd /tmp
tar czvf ./billing-tool-db-script-latest.tar.gz ./$TARGET_FOLDER

export AWS_PROFILE=billing-dev

### Upload the package to Prod environemnt billing-db-sql 
/usr/local/bin/aws s3 cp /tmp/billing-tool-db-script-latest.tar.gz s3://billing-deploy-package/packages/billing-tool-db-script-latest.tar.gz

rm -rf $TARGET_FOLDER
rm -rf /tmp/billing-tool-db-export-latest.tar.gz
