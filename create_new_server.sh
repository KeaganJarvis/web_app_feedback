#!/bin/bash
set -euo pipefail

# run inside the azure web shell

usage()
{
        echo 'create_new_server.sh [-k <asana-key>] [-f <force-no-key>] '
        echo -e "\t-k <asana-key>\t\t-\tAsana API key that will be installed on the new host"
        echo -e "\t-f <force-no-key>\t-\tForce runs the script without a specified Asana key"
        exit 125
}

create_server()
{
    if [ "$#" -lt "1" ];then
        usage
    fi
    # Would prefer to use Azure Key Vault or Hashicorp Vault to store secrets like the Asana API key
    # but this is a quick hack that allows the Asana API key to get passed into the system
    ASANA_KEY="Default_unset_key"
    while getopts ":k:f" opt; do
        case $opt in
            k)
            ASANA_KEY="$OPTARG"
            ;;
            f)
            ASANA_KEY="Forcefully_ran_script_to_not_create_key"
            ;;
            \?)
            echo "Invalid option: -$OPTARG" >&2
            ;;
        esac
        done
    git clone https://github.com/KeaganJarvis/web_app_feedback.git
    cd web_app_feedback/terraform
    if terraform init; then
        echo "Successfully init'd the terrform state"
        echo "Assuming this means the user is correctly logged into azure CLI."
        echo "Proceeding."
    else
        echo "ERROR"
        echo "Could not init the terraform state"
        echo "Most likely issue is the current user is not logged into the Azure CLI"
        echo "Please run 'az login' and follow the steps output to get logged in"
        exit 1
    fi
    terraform apply -var="asana_key=${ASANA_KEY}" -auto-approve
    terraform apply -var="asana_key=${ASANA_KEY}" -target azurerm_linux_virtual_machine.web_app_mvp_vm -auto-approve
    # TODO the randomly assigned public IP is only displayable after this ^ second `terraform apply` is run
    terraform output -raw tls_private_key
    echo "Successully created server, you can get shell access to it using the private key above^"
    echo "The server has the following public ip:"
    terraform output public_ip_address # this is the line that makes the double `terraform apply`s necessary above
    echo "The web site should be available via http on that IP after approximately 5 mins"
    echo "FINISHED"

}

create_server "$@" 2>&1