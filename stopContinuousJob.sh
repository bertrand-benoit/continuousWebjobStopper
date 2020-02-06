#!/bin/bash
#
# Author: Bertrand BENOIT <bertrand@bertrand-benoit.net>
# Version: 2.1
#
# Description: disable automagically all continuous Job of specified website.
#
# Sample: stopContinuousJob.sh itc-cegid

[ $# -lt 1 ] && echo -e "Usage: $0 <website>" >&2 && exit 1

website="$1"

function oldCliV1() {
  echo -e "If error occurs, you may need to run the following instructions:\n\tazure login"

  for continuousJob in $( azure site job list $website |grep continuous |awk '{print $2}' ); do
    echo -ne "Stopping continuous job $continuousJob ... "
    ! azure site job stop $continuousJob $website && echo "FAILED" >&2 && exit 2
    echo "OK"
  done
}

function defineResourceGroup() {
  local _website="$1"

  # Old way to define resource group ..
  # resourceGroupAlt="${website}-prod-rg"
  # resourceGroup="itclients-${website//itc-}-prod-rg"
  local namePart=$( echo "$_website" |sed -e 's/^itcp*-//')
  local resourceGroup=$( az group list |jq '.[].name' -r |uniq |grep -i "$namePart" )

  echo "Defined resource group for Website '$_website': '$resourceGroup'" >&2
  echo "$resourceGroup"
}

# usage: newCliV2 <website> <resource group>
function newCliV2() {
    local _website="$1" _resourceGroup="$2"

    echo -e "Loading continuous job list for website '$_website', in resource-group ''$_resourceGroup' ..."
    for continuousJob in $( az webapp webjob continuous list --name "$_website" --resource-group "$_resourceGroup" |jq '.[].name' -r |sed -e "s/$_website//"  ); do
      echo -e "Stopping continuous job $continuousJob ... "
      ! az webapp webjob continuous stop --name "$_website" --resource-group "$_resourceGroup" --webjob-name "$continuousJob" && echo "FAILED" >&2 && return 0
    done

    return 128
}

echo -e "If error occurs, you may need to run the following instructions:\n\taz login"
resourceGroup=$( defineResourceGroup "$website")
newCliV2 "$website" "$resourceGroup"
