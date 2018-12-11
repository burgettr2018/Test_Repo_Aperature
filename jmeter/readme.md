# RCE_upload.jmx

Create `users.csv` as a list of username,password for your env

## Command Line Parameters
 * env - e.g. (default) `devel`
 * max_files - max to upload per user (e.g. `5`) (default `1`)
 * max_users - max simultaneous users, also drives rampup time in seconds (default `1`) (pulled from `${env}_users.csv`, shouldn't exceed the number of users in file)
 * filesize - `small` or `large`, chooses if files come from `small_files.csv` or `large_files.csv`, respectively

Example:
`JVM_ARGS="-Xms512m -Xmx512m" ./jmeter.sh -n -e -Jenv=stage -Jmax_files=5 -Jmax_users=20 -Jfilesize=large -t ~/Projects/ums/jmeter/RCE_upload.jmx -l RCE_upload.jtl -o ~/Projects/ums/jmeter/results/output`
