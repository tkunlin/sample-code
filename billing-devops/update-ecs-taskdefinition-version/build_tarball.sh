#!/bin/bash

### This script will create billing-update-ecs-taskdefinition-version-vx.x.x.x.tar for deploy 
VERSION=`cat ./version.txt`

echo "$VERSION"

TARGET_FOLDER="update-ecs-taskdefinition-version"

FILENAME=billing-$TARGET_FOLDER-$VERSION.tar.gz


mkdir -p /tmp/$TARGET_FOLDER
cp -r ./* /tmp/$TARGET_FOLDER

cd /tmp
tar czvf ./$FILENAME ./$TARGET_FOLDER

export AWS_PROFILE=billing-dev

### Upload the package to Prod environemnt billing-db-sql 
/usr/local/bin/aws s3 cp /tmp/$FILENAME s3://billing-deploy-package/packages/$FILENAME

rm -rf /tmp/$TARGET_FOLDER
rm -rf /tmp/$FILENAME
