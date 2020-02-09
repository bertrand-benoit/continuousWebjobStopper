#!/bin/bash
#
# Author: Bertrand BENOIT <contact@bertrand-benoit.net>
# Version: 2.2
#
# Description: lists/stops all/specified continuous webjob(s) of a specified Azure Webapp.

#####################################################
#                General configuration.
#####################################################
export CATEGORY="stopContinuousJob"

currentDir=$( dirname "$( command -v "$0" )" )
export GLOBAL_CONFIG_FILE="$currentDir/default.conf"
export CONFIG_FILE="${HOME:-/home/$( whoami )}/.config/stopContinuousJob.conf"

scriptsCommonUtilities="$currentDir/scripts-common/utilities.sh"
[ ! -f "$scriptsCommonUtilities" ] && echo -e "ERROR: scripts-common utilities not found, you must initialize your git submodule once after you cloned the repository:\ngit submodule init\ngit submodule update" >&2 && exit 1
# shellcheck disable=1090
. "$scriptsCommonUtilities"

checkBin jq || errorMessage "This tool requires jq. Install it please, and then run this tool again."
checkBin az || errorMessage "This tool requires az (Azure CLI v2). Install it please, and then run this tool again."

checkAndSetConfig "patterns.removeMatchingParts" "$CONFIG_TYPE_OPTION"
REMOVE_NAME_MATCHING_PARTS="$LAST_READ_CONFIG"

#####################################################
#                Command line management.
#####################################################
# usage : usage
function usage() {
  echo "Usage: $0 -a|--webapp <webapp name> [-r|--resourceGroup <resource group>] [-w|--webjob <webjob name>] [--list] [--debug] [-h|--help]"
  echo -e "<webapp name>\tname of the webapp whose continuous job must be managed"
  echo -e "<resource group>name of the resource group which owns the webapp to manage (default: automatically detected according to your configuration)"
  echo -e "<webjob name>\tname of the webjob to manage (default: ALL webjob of the specfified webapp)"
  echo -e "--list\t\tlist continuous webjob instead of stopping them"
  echo -e "--debug\t\tshow debug information (activating scripts-common Debug mode)"
  echo -e "-h|--help\tshow this help"
}

listJobInsteadOfStop=0
while [ "${1:-}" != "" ]; do
  if [ "$1" == "--debug" ]; then
    export DEBUG_UTILITIES=1
  elif [ "$1" == "--list" ]; then
    listJobInsteadOfStop=1
  elif [ "$1" = "-a" ] || [ "$1" = "--webapp" ]; then
    shift
    webapp="$1"
  elif [ "$1" = "-r" ] || [ "$1" = "--resourceGroup" ]; then
    shift
    resourceGroup="$1"
  elif [ "$1" = "-w" ] || [ "$1" = "--webjob" ]; then
    shift
    webjob="$1"
  elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage && exit 0
  else
    usage
    errorMessage "Unknown parameter '$1'"
  fi

  shift
done

# Ensures needed variables are defined.
[ -z "${webapp:-}" ] && usage && errorMessage "You must specify the Webapp."

#####################################################
#                Functions.
#####################################################
# Usage: oldCliV1 <webapp>
# Previous version with Azure CLI v1, for information.
function oldCliV1() {
  writeMessage "If error occurs, you may need to run the following instructions:\n\tazure login"

  for continuousJob in $( azure site job list "$webapp" |grep continuous |awk '{print $2}' ); do
    writeMessageSL "Stopping continuous job $continuousJob ... "
    ! azure site job stop "$continuousJob" "$webapp" && echo "FAILED" >&2 && continue
    echo "OK"
  done
}

# Usage: checkCLIV2Login
function checkCLIV2Login() {
  az account list >/dev/null 2>&1
}

# Usage: defineResourceGroup <webapp>
function defineResourceGroup() {
  local _webapp="$1" namePart resourceGroup

  namePart=$( removeAllSpecifiedPartsFromString "$_webapp" "$REMOVE_NAME_MATCHING_PARTS" "1" )
  resourceGroup=$( az group list |jq '.[].name' -r |uniq |grep -i "$namePart" ) \
    || errorMessage "Unable to define resource group for Webapp '$webapp'. Ensure your configuration file is OK, and your az CLI is logged in."
  echo "$resourceGroup"
}

# Usage: newCliV2 <webapp> <resource group> [<webjob>]
function newCliV2() {
    local _webapp="$1" _resourceGroup="$2" _webjob="${3:-}"

    writeMessage "Loading continuous webjob list for webapp '$_webapp', in resource-group '$_resourceGroup' ..."
    for continuousJob in $( az webapp webjob continuous list --name "$_webapp" --resource-group "$_resourceGroup" |jq '.[].name' -r |sed -e "s/$_webapp\///"  ); do
      # Checks if a specific webjob has been requested.
      if [ -n "$_webjob" ]; then
        [[ "$_webjob" != "$continuousJob" ]] && continue
      fi

      # Checks if list must be performed instead of stop.
      if [ "$listJobInsteadOfStop" -eq 1 ]; then
        writeMessage "Found continuous webjob: $continuousJob"
      else
        writeMessage "Stopping continuous webjob '$continuousJob' ... "
        ! az webapp webjob continuous stop --name "$_webapp" --resource-group "$_resourceGroup" --webjob-name "$continuousJob" && warning "Failed to stop continuous job $continuousJob."
      fi
    done
}

#####################################################
#                Instructions.
#####################################################
writeMessage "Checking az CLI is logged ON."
checkCLIV2Login || errorMessage "It seems error occurs, you may need to run the following instructions:\n\taz login"

if [ -z "${resourceGroup:-}" ]; then
  resourceGroup=$( defineResourceGroup "$webapp" ) || exit 1
  writeMessage "Defined resource group for Webapp '$webapp': '$resourceGroup'"
fi

newCliV2 "$webapp" "$resourceGroup" "${webjob:-}"
