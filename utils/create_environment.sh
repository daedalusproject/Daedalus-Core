#!/bin/bash
#title           :create_environment.sh
#description     :This script creates Kubernetes environment for Daedalus Core pipelines.
#author          :Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>
#date            :20190423

## Variables

KUBERNETES_CONFIG_FOLDER="Kubernetes"
KUBE_CLUSTER_CRT="$KUBERNETES_CONFIG_FOLDER/windmaker.pem"
## Functions

show_error() {

  echo "$@" 1>&2
}

### Check environment variables

function check_required_environment_variables {

   errors=0

   for environment_variable in ${REQUIRED_VARIABLES[@]}
   do
       echo $environment_variable
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

    declare -A CONFIGMAP_FILES
    CONFIGMAP_FILES["redis-config"]="$KUBERNETES_CONFIG_FOLDER/config/redis/redis.conf"
    CONFIGMAP_FILES["rabbitmq-config"]="$KUBERNETES_CONFIG_FOLDER/config/rabbitmq"

    case $ENV_TYPE in
        testing)
            KUBERNETES_NAMESPACE="daedalus-core-testing"
            KUBERNETES_USER_TOKEN="${KUBERNETES_TESTING_USER_TOKEN}"
            KUBERNETES_USER="${KUBERNETES_TESTING_USER_NAME}"
            ENV_FOLDER="$KUBERNETES_CONFIG_FOLDER/daedalus-core-testing"
            ENV_FILES=("testing-environment.yml")
            CONFIGMAP_NAMES=("redis-config", "rabbitmq-config")
            REDIS_SERVICE="redis-daedalus-core-testing.daedalus-core-testing.svc.cluster.local"
            ;;
        develop)
            KUBERNETES_NAMESPACE="daedalus-core-develop"
            KUBERNETES_USER_TOKEN="${KUBERNETES_TESTING_USER_TOKEN}"#For the time being all envs use the same user
            KUBERNETES_USER="${KUBERNETES_TESTING_USER_NAME}"#For the time being all envs use the same user
            ENV_FOLDER="$KUBERNETES_CONFIG_FOLDER/daedalus-core-develop"
            ENV_FILES=("develop-environment.yml")
            CONFIGMAP_NAMES=("redis-config", "rabbitmq-config")
            REDIS_SERVICE="redis-daedalus-core-develop.daedalus-core-develop.svc.cluster.local"
            ;;
        *)
            show_error "Environment $ENV_TYPE not defined."
            exit 1

    esac
}

function create_kube_config {

    kubectl config set-cluster default --server=$KUBE_URL --certificate-authority=$KUBE_CLUSTER_CRT
    kubectl config set-credentials $KUBERNETES_USER --token=$KUBERNETES_USER_TOKEN
    kubectl config set-context default --cluster=default --user=$KUBERNETES_USER
    kubectl config use-context default
}

function delete_env_and_configs {

    for file in $ENV_FILES
    do
        kubectl -n $KUBERNETES_NAMESPACE delete -f $ENV_FOLDER/$file --ignore-not-found=true
    done

    for configmap in $CONFIGMAP_NAMES
    do
        kubectl -n $KUBERNETES_NAMESPACE delete configmap $configmap --ignore-not-found=true
    done
}

function create_env_and_configs {

    for configmap in $CONFIGMAP_NAMES
    do
        kubectl -n $KUBERNETES_NAMESPACE create configmap $configmap --from-file $CONFIGMAP_FILES[$configmap]
    done

    for file in $ENV_FILES
    do
        kubectl -n $KUBERNETES_NAMESPACE apply -f $ENV_FOLDER/$file --ignore-not-found=true
    done
}

function wait_for_redis {

    SLEEP=10
    ATTEMPTS=5

    counter=0

    while [[ $counter < $ATTEMPTS ]]
    do
        redis-cli -h $REDIS_SERVICE ping > /dev/null 2>&1
        if [[ $? == 0 ]]; then
            break
        fi
        let "counter++"
        sleep $SLEEP
    done

    if [[ $counter == $ATTEMPTS ]]; then
        exit 1
    fi
    exit 0
}

function test_redis {

    echo "Hello" | redis-cli -h $REDIS_SERVICE -x set greeting
    redis-cli -h $REDIS_SERVICE get greeting
}
## Main

check_required_environment_variables
