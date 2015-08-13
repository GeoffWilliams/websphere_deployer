class websphere_deployer::params {
  # base directory
  $base_dir             = "/opt/ibm/deployments"

  # user to run deployment scripts as (also used for file ownership)
  $user                 = "wsadmin"

  # group to set file ownership to (when writable)
  $group                = "wsadmin"

  # directory under $base_dir to store scripts
  $script_dir_name      = "scripts"

  # directory under $base_dir to store binaries
  $bin_dir_name         = "bin"

  # directory under $base_dir to store downloaded ear files
  $incoming_dir_name    = "incoming"

  # fully quallified incoming directory 
  $incoming_dir         = "${base_dir}/${incoming_dir_name}"
 
  # directory under $base_dir to write out .properties files
  $properties_dir_name  = "properties"

  # fully qualified properties directory
  $properties_dir       = "${base_dir}/${properties_dir_name}" 
  # list of script files to install into the scripts directory.  These will
  # be sourced from the puppet fileserver
  $script_files         = [
    "restartAppServer.sh",
    "startAppServer.sh",
    "stopAppServer.sh",
    "was_deploy.py",
  ] 

  # list of bin files to install into to the bin directory.  These are just
  # scripts too so the decision as to which directory to put stuff in is 
  # somewhat arbitrary.
  $bin_files            = [
    "env.sh",
    "deploymgr.sh",
  ]

  # list of files that are set to RW for $user
  $rw_dirs              = [
    "${base_dir}/error",
    $incoming_dir,
    "${base_dir}/logs",
    "${base_dir}/processed",
    "${base_dir}/processing",
    $properties_dir,
    "${base_dir}/wget",
  ]

  # list of files that are root owned with restrictive permissions
  $ro_dirs              = [
    "${base_dir}/${bin_dir_name}",
    "${base_dir}/${script_dir_name}",
  ]

  # munged path directory for exec resources 
  $exec_path            = [
    $ro_dirs,
    "/usr/bin",
    "/bin",
  ]

  # list of minutes to run the main cron job.  Has to be a list of individual
  # minutes due to cron version used on solaris machines
  $deploy_freq          = [0,5,10,15,20,25,30,35,40,45,50,55]

  # broken out date command to use for logfile creation
  $date_command         = '`/usr/bin/date \+\%Y-\%m-\%d`'

  # munged cron command to run
  $cron_command         = "${base_dir}/bin/deploymgr.sh >> ${base_dir}/logs/deploymgr.log.${date_command} 2>&1"
 
  # regular expression to match a valid version.  If you change this, make sure
  # to also fixup the RSpec tests
  $version_regexp       = '\d+\.\d+\.\d+'
}
