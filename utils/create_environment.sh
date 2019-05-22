#!/bin/bash
#title           :create_environment.sh
#description     :This script creates Kubernetes environment for Daedalus Core pipelines.
#author          :Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>
#date            :20190423

## Variables

KUBERNETES_CONFIG_FOLDER="kubernetes"
KUBE_CLUSTER_CRT="$KUBERNETES_CONFIG_FOLDER/windmaker.pem"
## Functions

function show_error {

  echo "$@" 1>&2
}

### Check environment variables

function check_required_environment_variables {

   errors=0

   for environment_variable in ${REQUIRED_VARIABLES[@]}
   do
       if [[ -z ${!environment_variable} ]]; then
           show_error "$environment_variable is not defined"
           errors=1
       fi
   done
   if [[ $errors == 1 ]]; then
       exit 1
   fi
}

function evalue_env_type {

    declare -g -A CONFIGMAP_FILES
    CONFIGMAP_FILES["redis-config"]="$KUBERNETES_CONFIG_FOLDER/config/redis/redis.conf"
    CONFIGMAP_FILES["rabbitmq-config"]="$KUBERNETES_CONFIG_FOLDER/config/rabbitmq"

    declare -g -A CONFIGMAPS

    case $ENV_TYPE in
        testing)
            KUBERNETES_NAMESPACE="daedalus-core-testing"
            KUBERNETES_USER_TOKEN="${KUBERNETES_TESTING_USER_TOKEN}"
            KUBERNETES_USER_NAME="${KUBERNETES_TESTING_USER_NAME}"
            ENV_FOLDER="$KUBERNETES_CONFIG_FOLDER/daedalus-core-testing"
            ENV_FILES=("testing-environment.yml")
            CONFIGMAP_NAMES=("redis-config" "rabbitmq-config")
            REDIS_SERVICE="redis-daedalus-core-testing.daedalus-core-testing.svc.cluster.local"
            ;;
        develop)
            KUBERNETES_NAMESPACE="daedalus-core-develop"
            KUBERNETES_USER_TOKEN="${KUBERNETES_DEVELOP_USER_TOKEN}" 
            KUBERNETES_USER_NAME="${KUBERNETES_DEVELOP_USER_NAME}" 
            ENV_FOLDER="$KUBERNETES_CONFIG_FOLDER/daedalus-core-develop"
            ENV_FILES=("develop-environment.yml")
            CONFIGMAP_NAMES=("redis-config" "rabbitmq-config")
            REDIS_SERVICE="redis-daedalus-core-develop.daedalus-core-develop.svc.cluster.local"
            CONFIGMAPS["percona-server"]="$KUBERNETES_CONFIG_FOLDER/config/percona-server/percona-server-env.yml"
            sed -i "s/__DAEDALUS_CORE_DATABASE_PASSWORD__/$DAEDALUS_CORE_DEVELOP_NEW_USER_PASSWORD/g" $KUBERNETES_CONFIG_FOLDER/config/daedalus-core/daedalus_core_develop.conf
            ;;
        *)
            show_error "Environment $ENV_TYPE not defined."
            exit 1

    esac
}

function create_kube_config {

    kubectl config set-cluster default --server=$KUBERNETES_URL --certificate-authority=$KUBERNETES_CLUSTER_CRT
    kubectl config set-credentials $KUBERNETES_USER_NAME --token=$KUBERNETES_USER_TOKEN
    kubectl config set-context default --cluster=default --user=$KUBERNETES_USER_NAME
    kubectl config use-context default
}

function delete_env_and_configs {

    for file in ${ENV_FILES[@]}
    do
        kubectl -n $KUBERNETES_NAMESPACE delete -f $ENV_FOLDER/$file --ignore-not-found=true
    done

    for configmap in ${CONFIGMAP_NAMES[@]}
    do
        kubectl -n $KUBERNETES_NAMESPACE delete configmap $configmap --ignore-not-found=true
    done

    for configmap in ${CONFIGMAPS[@]}
    do
        kubectl -n $KUBERNETES_NAMESPACE delete -f $configmap --ignore-not-found=true
    done

    if [ "$ENV_TYPE" == "develop" ]; then
        kubectl -n $KUBERNETES_NAMESPACE delete secret generic percona-secrets --ignore-not-found=true
        kubectl -n $KUBERNETES_NAMESPACE delete secret generic daedalus-core-secrets --ignore-not-found=true
        kubectl -n $KUBERNETES_NAMESPACE delete secret generic daedalus-core-rsa-keys --ignore-not-found=true
        kubectl -n $KUBERNETES_NAMESPACE delete secret generic daedalus-core-database --ignore-not-found=true
        kubectl -n $KUBERNETES_NAMESPACE delete secret generic daedalus-core-cache --ignore-not-found=true
        kubectl -n $KUBERNETES_NAMESPACE delete secret generic daedalus-core-admin-info --ignore-not-found=true
    fi
}

function create_env_and_configs {

    if [ "$ENV_TYPE" == "develop" ]; then
        kubectl -n $KUBERNETES_NAMESPACE create secret generic percona-secrets --from-literal=MYSQL_NEW_ROOT_PASSWORD="$DAEDALUS_CORE_DEVELOP_NEW_ROOT_PASSWORD" --from-literal=MYSQL_NEW_USER_PASSWORD="$DAEDALUS_CORE_DEVELOP_NEW_USER_PASSWORD" --from-literal=MYSQL_NEW_USER_HOST="$KUBE_CDIR"
        kubectl -n $KUBERNETES_NAMESPACE create secret generic daedalus-core-secrets --from-file=$KUBERNETES_CONFIG_FOLDER/config/daedalus-core
        kubectl -n $KUBERNETES_NAMESPACE create secret generic daedalus-core-rsa-keys --from-file=$KUBERNETES_CONFIG_FOLDER/config/daedalus-core/secrets
        kubectl -n $KUBERNETES_NAMESPACE create secret generic daedalus-core-database --from-literal=MYSQL_USER="daedalus" --from-literal=MYSQL_PASSWORD="$DAEDALUS_CORE_DEVELOP_NEW_USER_PASSWORD" --from-literal=MYSQL_HOST="percona-server-develop" --from-literal=MYSQL_PORT="3306" --from-literal=MYSQL_DATABASE="daedalus_core_realms" --from-literal=MYSQL_CONECTION_RETRIES="7" --from-literal=MYSQL_CONECTION_TIMEOUT="10"
        kubectl -n $KUBERNETES_NAMESPACE create secret generic daedalus-core-cache --from-literal=REDIS_HOST="redis-daedalus-core-develop" --from-literal=REDIS_PORT="6379" --from-literal=REDIS_CONECTION_RETRIES="5" --from-literal=REDIS_CONECTION_TIMEOUT="5"
        kubectl -n $KUBERNETES_NAMESPACE create secret generic daedalus-core-admin-info --from-literal=ADMIN_NAME="$DEVELOP_ADMIN_NAME" --from-literal=ADMIN_SURNAME="$DEVELOP_ADMIN_SURNAME" --from-literal=ADMIN_EMAIL="$DEVELOP_ADMIN_EMAIL" --from-literal=ADMIN_PASSWORD="$DEVELOP_ADMIN_PASSWORD"
    fi

    for configmap in ${CONFIGMAP_NAMES[@]}
    do
        echo ${CONFIGMAP_FILES[$configmap]}
        kubectl -n $KUBERNETES_NAMESPACE create configmap $configmap --from-file ${CONFIGMAP_FILES[$configmap]}
    done

    for configmap in ${CONFIGMAPS[@]}
    do
        kubectl -n $KUBERNETES_NAMESPACE apply -f $configmap
    done

    for file in ${ENV_FILES[@]}
    do
        kubectl -n $KUBERNETES_NAMESPACE apply -f $ENV_FOLDER/$file
    done

}

## Main

check_required_environment_variables
evalue_env_type
