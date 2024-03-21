#!/usr/bin/env bash

### Description: convert step function to uat
### Create by Richrad.Tsai 2023-10-24
### 

### Fail fast
set -Eeuo pipefail

input_filename=$1
output_filename=$2

### 
/usr/bin/cp $1 $2


### env replaced
/usr/bin/sed -i "s/\"Dev\"/\"Uat\"/g" $2
#/usr/bin/sed -i "s/dev/uat/g" $2
/usr/bin/sed -i "s/-dev-/-uat-/g" $2
/usr/bin/sed -i "s/_dev_/_uat_/g" $2

### AWS ID replaced
# /usr/bin/sed -i "s/863203846708/960216436767/g" $2


### security-group &  subnets replaced
ecv_dev_subnets_1="subnet-031425f6c9b3838bd"
ecv_dev_subnets_2="subnet-0f1cc7d041343c904"
ecv_dev_sg="sg-0925271d926b84730"

ecv_uat_subnets_1="subnet-0e3bfe4f24cdd9a79"
ecv_uat_subnets_2="subnet-0a8cd931897f61be9"
ecv_uat_sg="sg-052031cd3d90057b9"

ecv_stage_subnets_1="subnet-07441370101acec1c"
ecv_stage_subnets_1="subnet-01da4771bd3195aa6"
ecv_stage_sg="sg-06bf17ebdda9cb944"

ecv_prod_subnets_1=""
ecv_prod_subnets_2=""
ecv_prod_sg=""


/usr/bin/sed -i "s/${ecv_dev_subnets_1}/${ecv_uat_subnets_1}/g" $2
/usr/bin/sed -i "s/${ecv_dev_subnets_2}/${ecv_uat_subnets_2}/g" $2
/usr/bin/sed -i "s/${ecv_dev_sg}/${ecv_uat_sg}/g" $2

### UserData replaced
dev_userdata="IyEvYmluL2Jhc2gKZWNobyAiRUNTX0NMVVNURVI9YmlsbGluZy1kZXYtam9iICI+PiAvZXRjL2Vjcy9lY3MuY29uZmln"
uat_userdata="IyEvYmluL2Jhc2gKZWNobyAiRUNTX0NMVVNURVI9YmlsbGluZy11YXQtam9iICI+PiAvZXRjL2Vjcy9lY3MuY29uZmln"
stage_userdata="IyEvYmluL2Jhc2gKZWNobyAiRUNTX0NMVVNURVI9YmlsbGluZy1zdGFnZS1qb2IgIj4+IC9ldGMvZWNzL2Vjcy5jb25maWc="
prod_userdata=""

/usr/bin/sed -i "s/${dev_userdata}/${uat_userdata}/g" $2