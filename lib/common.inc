#
# Common functions for use with scripts interactiving with the virtualmin wrappers
#
# Copyright (c) 2014 Jacques Marneweck.  All rights reserved.
#

function has_feature() {
  local domain=$2
  local feature=$1

  vmin list-domains --name-only --with-feature ${feature} --domain ${domain} | grep ${domain}
  if [[ $? -eq 0 ]]; then
    return 1
  else
    return 0
  fi
}
