#!/opt/local/bin/bash
#
# Attempts to restore an account from a Virtualmin backup tarball by restoring
# each domain in turn.
#

#
# Copyright (c) 2014 Jacques Marneweck. All rights reserved.
# Copyright (c) 2014 Václav Strachoň. All rights reserved.
# Copyright (c) 2014 Kaizen Garden.  All rights reserved.
#

set -o errexit
set -o pipefail
export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -o xtrace

set -x

export LANG=C
export PATH=/opt/local/gnu/bin:/opt/local/bin:/opt/local/sbin:/usr/bin:/usr/sbin

vmin_base=/opt/webmin/virtual-server

if [ -z $2 ]; then
  echo "Usage: ${0} [username] [domain]"
  echo "e.g. ${0} jacques powertrip.co.za"
  exit 1
fi

user=$1
domain=$2
backup_file=/var/tmp/${user}.tar.gz

if [[ ! -f $backup_file ]]; then
  echo "[ERROR] ${backup_file} does not exist."
  exit 1
fi

#
# FIXME: Check if the domain exists in the tarball before trying to restore.
# FIXME: Figure out which domain is the primary domain and restore that first.
#

#
# Restore a domain and ignore powerdns and mail
#
${vmin_base}/restore-domain.pl --domain ${domain} --source ${backup_file} \
  --all-features --except-feature mail --except-feature virtualin-powerdns \
  --skip-warnings

#
# Unfortunately the webmin restored apache configuration is broken.  You need
# to disable first disable the web feature and then re-enable with logrotation.
# Handles the cases where the virtualmin-dav and virtualmin-svn plugins are
# enabled on a domain.
#
vmin list-domains --domain ${domain} --multiline | grep dav
if [[ $? -eq 0 ]]; then
  have_dav=1
else
  have_dav=0
fi

vmin list-domains --domain ${domain} --multiline | grep svn
if [[ $? -eq 0 ]]; then
  have_svn=1
else
  have_svn=0
fi

if [[ $have_dav -eq 1 ]]; then
  vmin disable-feature --domain ${domain} --virtualmin-dav
fi

if [[ $have_svn -eq 1 ]]; then
  vmin disable-feature --domain ${domain} --virtualmin-svn
fi

vmin disable-feature --domain ${domain} --logrotate
vmin disable-feature --domain ${domain} --web
vmin enable-feature --domain ${domain} --web
vmin enable-feature --domain ${domain} --logrotate

if [[ $have_dav -eq 1 ]]; then
  vmin enable-feature --domain ${domain} --virtualmin-dav
fi

if [[ $have_svn -eq 1 ]]; then
  vmin enable-feature --domain ${domain} --virtualmin-svn
fi
