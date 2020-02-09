#!/bin/bash
#
# Author: Bertrand BENOIT <contact@bertrand-benoit.net>
# Version: 2.2
#
# Description: stops automatically all continuous Jobs of specified Azure website.

#####################################################
#                General configuration.
#####################################################
export CATEGORY="stopContinuousJob"

currentDir=$( dirname "$( command -v "$0" )" )
export GLOBAL_CONFIG_FILE="$currentDir/default.conf"
export CONFIG_FILE="${HOME:-/home/$( whoami )}/.config/stopContinuousJob.conf"

# shellcheck disable=1090
[ -n "$SCRIPTS_COMMON_PATH" ] && . "$SCRIPTS_COMMON_PATH"

checkBin jq || errorMessage "This tool requires jq. Install it please, and then run this tool again."
checkBin az || errorMessage "This tool requires az (Azure CLI v2). Install it please, and then run this tool again."

checkAndSetConfig "patterns.removeMatchingParts" "$CONFIG_TYPE_OPTION"
REMOVE_NAME_MATCHING_PARTS="$LAST_READ_CONFIG"

#####################################################
#                Command line management.
#####################################################
[ $# -lt 1 ] && errorMessage "Usage: $0 <website>"
website="$1"

#####################################################
#                Functions.
#####################################################
# Usage: oldCliV1 <website>
# Previous version with Azure CLI v1, for information.
function oldCliV1() {
  writeMessage "If error occurs, you may need to run the following instructions:\n\tazure login"

  for continuousJob in $( azure site job list "$website" |grep continuous |awk '{print $2}' ); do
    writeMessageSL "Stopping continuous job $continuousJob ... "
    ! azure site job stop "$continuousJob" "$website" && echo "FAILED" >&2 && continue
    echo "OK"
  done
}

# Usage: checkCLIV2Login
function checkCLIV2Login() {
  az account list >/dev/null 2>&1
}

# Usage: defineResourceGroup <website>
function defineResourceGroup() {
  local _website="$1" namePart resourceGroup

  namePart=$( removeAllSpecifiedPartsFromString "$_website" "$REMOVE_NAME_MATCHING_PARTS" "1" )
  resourceGroup=$( az group list |jq '.[].name' -r |uniq |grep -i "$namePart" ) \
    || errorMessage "Unable to define resource group for Website '$website'. Ensure your configuration file is OK, and your az CLI is logged in."
  echo "$resourceGroup"
}

# Usage: newCliV2 <website> <resource group>
function newCliV2() {
    local _website="$1" _resourceGroup="$2"

    writeMessage "Loading continuous job list for website '$_website', in resource-group ''$_resourceGroup' ..."
    for continuousJob in $( az webapp webjob continuous list --name "$_website" --resource-group "$_resourceGroup" |jq '.[].name' -r |sed -e "s/$_website//"  ); do
      writeMessage "Stopping continuous job $continuousJob ... "
      ! az webapp webjob continuous stop --name "$_website" --resource-group "$_resourceGroup" --webjob-name "$continuousJob" && warning "Failed to stop continuous job $continuousJob."
    done
}

#####################################################
#                Instructions.
#####################################################
writeMessage "Checking az CLI is logged ON."
checkCLIV2Login || errorMessage "It seems error occurs, you may need to run the following instructions:\n\taz login"

resourceGroup=$( defineResourceGroup "$website" ) || exit 1
writeMessage "Defined resource group for Website '$website': '$resourceGroup'"
newCliV2 "$website" "$resourceGroup"
