echo "additional_after_install.sh started."
APPNAME=$(echo $APPLICATION_NAME | awk -F"CDAPP-" '{print $2}' | awk -F"-STAGE" '{print $1}' | awk -F"-PROD" '{print $1}' | awk -F"-DEV" '{print $1}')
APPTYPE=$(echo $APPLICATION_NAME | awk -F"-" '{print $3}')

echo "APPTYPE = $APPTYPE"

# bundle install and rake tasks need to be run as ec2-user
su -l ec2-user << EOF

APPNAME=$(echo $APPLICATION_NAME | awk -F"CDAPP-" '{print $2}' | awk -F"-STAGE" '{print $1}' | awk -F"-PROD" '{print $1}' | awk -F"-DEV" '{print $1}' | awk -F"-Development" '{print $1}')
cd /data/${APPNAME}

if [ -e Rakefile ]; then
  echo Starting rake db:migrate
  rake db:migrate
  echo Finished rake db:migrate
  echo Starting rake data:migrate
  rake data:migrate
  echo Finished rake data:migrate
fi

if [ -e package.json ]; then
  echo Starting npm install
  npm install
  echo Finished npm install
fi

EOF

# lexically include the DJ restart kills, here, instead of calling it
echo Starting jobs kill
cd /data/ums
if [ -f /etc/jobs ]; then
    echo Starting restart dj workers for $APPNAME $APPTYPE
    echo Starting jobs kill task 
    echo listing PIDs: 
    for pid in `ps ax | grep "rake jobs:work" | awk '{print $1}' | xargs pwdx | grep "/data/ums" | cut -f1 -d':'` ; do
      echo "$pid"
    done
    echo attempting a nice kill of PIDs
    for pid in `ps ax | grep "rake jobs:work" | awk '{print $1}' | xargs pwdx | grep "/data/ums" | cut -f1 -d':'` ; do kill "$pid" ; done 
    sleep 10
    echo attempting a hard kill of PIDs
    for pid in `ps ax | grep "rake jobs:work" | awk '{print $1}' | xargs pwdx | grep "/data/ums" | cut -f1 -d':'` ; do kill -9 "$pid" ; done 
    sleep 10
fi

echo Restarting DJ workers
nohup /data/ums/restart_dj_workers.sh $APPTYPE > /data/ums/log/workoff_default.log 2>&1 &
echo "Return code: restart_dj_workers.sh" $?

echo "additional_after_install.sh ended."
