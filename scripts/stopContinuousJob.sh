#!/bin/bash
#
# Author: Bertrand BENOIT <bertrand@bertrand-benoit.net>
# Version: 2.0
#
# Description: diable automagically all continuous Job of specified website.
#
# Sample: stopContinuousJob.sh itc-cegid

[ $# -lt 1 ] && echo -e "Usage: $0 <website>" >&2 && exit 1

# N.B.: resource group may be named differently, and thus it would not work.
website="$1"
resourceGroup="itclients-${website//itc-}-prod-rg"

function oldCliV1() {
  echo -e "If error occurs, you may need to run the following instructions:\n\tazure login"

  for continuousJob in $( azure site job list $website |grep continuous |awk '{print $2}' ); do
    echo -ne "Stopping continuous job $continuousJob ... "
    ! azure site job stop $continuousJob $website && echo "FAILED" >&2 && exit 2
    echo "OK"
  done
}

# usage: newCliV2 <website> <resource group>
function newCliV2() {
    local _website="$1" _resourceGroup="$2"

    echo -e "Loading continuous job list for website '$_website', in resource-group ''$_resourceGroup' ..."
    for continuousJob in $( az webapp webjob continuous list --name "$_website" --resource-group "$_resourceGroup" |jq '.[].name' -r |sed -e "s/$_website//"  ); do
      echo -e "Stopping continuous job $continuousJob ... "
      ! az webapp webjob continuous stop --name "$_website" --resource-group "$_resourceGroup" --webjob-name "$continuousJob" && echo "FAILED" >&2 && exit 2
    done
}

newCliV2 "$website" "$resourceGroup"
