#!/bin/bash

set -euo pipefail

get_outputs() {
  echo `aws ssm get-parameter --name /terraform_staff_infrastructure_monitoring/$ENV/outputs | jq -r .Parameter.Value`
}

create_kubeconfig(){
  echo "Creating kubeconfig file"
  outputs=$(get_outputs)

  assume_role=$(echo $outputs | jq '.assume_role.value' | sed 's/"//g')
  TEMP_ROLE=`aws sts assume-role --role-arn $assume_role --role-session-name ci-authenticate-kubernetes-782`

  access_key=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.AccessKeyId')
  secret_access_key=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SecretAccessKey')
  session_token=$(echo "${TEMP_ROLE}" | jq -r '.Credentials.SessionToken')
  cluster_name=$(echo $outputs | jq  '.eks_cluster_id.value' | sed 's/"//g')

  AWS_ACCESS_KEY_ID=$access_key AWS_SECRET_ACCESS_KEY=$secret_access_key AWS_SESSION_TOKEN=$session_token aws eks\
    --region eu-west-2 update-kubeconfig --name $cluster_name --role-arn $assume_role
}

upgrade_auth_configmap(){
  outputs=$(get_outputs)
  cluster_role_arn=$(echo $outputs | jq '.eks_cluster_worker_iam_role_arn.value' | sed 's/"//g')
  echo "Deploying auth configmap"
  helm upgrade --install --atomic mojo-$ENV-ima-configmap ./kubernetes/auth-configmap --set rolearn=$cluster_role_arn
}

get_role_arn_for_account(){
  outputs=$(get_outputs)
  [[ $ENV == "production" ]] \
    && role_arn=`aws ssm get-parameter --name /terraform_staff_infrastructure_monitoring/$1/outputs | jq -r .Parameter.Value | jq .cloudwatch_exporter_assume_role_arn | sed 's/"//g'`\
    || role_arn=""
  echo $role_arn
}

get_cloudwatch_exporter_role_arns(){
  outputs=$(get_outputs)
  role_arn=`aws ssm get-parameter --name /terraform_staff_infrastructure_monitoring/$ENV/outputs | jq -r .Parameter.Value | jq .cloudwatch_exporter_access_role_arns.value | sed 's/"//g'`\
    || role_arn=""
  echo $role_arn
}

upgrade_ima_chart(){
  outputs=$(get_outputs)
  cluster_role_arn=$(echo $outputs | jq '.eks_cluster_worker_iam_role_arn.value' | sed 's/"//g')
  prometheus_image_repo=$(echo $outputs | jq '.prometheus_repository_v2.value.repository_url' | sed 's/"//g')
  prometheus_thanos_storage_bucket_name=$(echo $outputs | jq '.prometheus_thanos_storage_bucket_name.value' | sed 's/"//g')
  prometheus_thanos_storage_kms_key_id=$(echo $outputs | jq '.prometheus_thanos_storage_kms_key_id.value' | sed 's/"//g')
  cloudwatch_exporter_access_role_arns=$(get_cloudwatch_exporter_role_arns | sed 's/,/\\,/g')

  echo "Deploying IMA Helm chart"
  helm upgrade --install mojo-$ENV-ima ./kubernetes/infrastructure-monitoring --set \
environment=$ENV,\
prometheus.image=$prometheus_image_repo,\
alertmanager.image=prom/alertmanager,\
prometheusThanosStorageBucket.bucketName=$prometheus_thanos_storage_bucket_name,\
prometheusThanosStorageBucket.kmsKeyId=$prometheus_thanos_storage_kms_key_id,\
thanos.image=$THANOS_IMAGE_REPOSITORY_URL,\
cloudwatchExporter.accessRoleArns=$cloudwatch_exporter_access_role_arns,\
cloudwatchExporter.image=$CLOUDWATCH_EXPORTER_IMAGE_REPOSITORY_URL
}

main(){
  export KUBECONFIG="./kubernetes/kubeconfig"

  create_kubeconfig
  upgrade_auth_configmap
  upgrade_ima_chart

  # Display all Pods
  echo "List of Pods:"
  kubectl get pods
}

main
