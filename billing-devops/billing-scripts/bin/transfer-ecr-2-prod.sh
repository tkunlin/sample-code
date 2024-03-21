project_name=$1
version=$2

aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 863203846708.dkr.ecr.us-west-2.amazonaws.com
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 960216436767.dkr.ecr.us-west-2.amazonaws.com


docker pull 006920391431.dkr.ecr.us-west-2.amazonaws.com/$project_name:$version
docker tag  006920391431.dkr.ecr.us-west-2.amazonaws.com/$project_name:$version 863203846708.dkr.ecr.us-west-2.amazonaws.com/$project_name:$version
docker push 863203846708.dkr.ecr.us-west-2.amazonaws.com/$project_name:$version


