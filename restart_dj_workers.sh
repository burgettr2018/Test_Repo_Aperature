#!/bin/bash

export APPTYPE=$1

sudo su -l ec2-user << EOF

  if [ -f /etc/jobs ]; then    
      cd /data/ums

      # see similar script in mdms for example conditions/options
      /home/ec2-user/.rvm/gems/ruby-2.3.0/bin/rake jobs:work > /dev/null 2> /dev/null < /dev/null &
  fi

EOF

# kill all DJ daemon not in current tmp/pids
# this lists the tmp/pids and the ps for "delayed" in mdms folder and kills the pids not present in tmp/pids
# removed because the /tmp/pid's directory is deleted with each load...
#if [ -f /etc/jobs ]; then
#    comm -13 <(ls /data/ums/tmp/pids/delayed_job.*.pid | xargs -I % cat % | sort) <(ps ax | grep "delayed" | awk '{print $1}' | xargs pwdx | grep "/data/ums" | cut -f1 -d':' | sort) | xargs --no-run-if-empty kill -9
#fi
