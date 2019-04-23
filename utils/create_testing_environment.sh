#!/bin/bash
#title           :create_environment.sh
#description     :This script creates Kubernetes environment for Daedalus Core pipelines.
#author          :Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>
#date            :20190423

# Check environment variables

show_error() {
  echo "$@" 1>&2
}

function check_required_environment_variables {
   environment_variables=$@
   errors=0

   for environment_variable in $environment_variables
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

# Main

ENV_TYPE=$1

check_required_environment_variables ENV_TYPE
check_required_environment_variables KUBE_URL KUBE_TESTING_USER_TOKEN KUBE_TESTING_USER
check_required_environment_variables
