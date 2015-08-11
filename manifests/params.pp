class websphere_deployer::params {
  $base_dir          = "/opt/ibm/deployments"
  $user              = "wsadmin"
  $group             = "wsadmin"
  $script_dir_name   = "scripts"
  $bin_dir_name      = "bin"
  $incoming_dir_name = "incoming"
  $incoming_dir      = "${base_dir}/${incoming_dir_name}"
  
  $script_files = [
    "restartAppServer.sh",
    "startAppServer.sh",
    "stopAppServer.sh",
    "was_deploy.py",
  ] 

  $bin_files = [
    "env.sh",
    "deploymgr.sh",
  ]

  $rw_dirs = [
    "${base_dir}/error",
    $incoming_dir,
    "${base_dir}/logs",
    "${base_dir}/processed",
    "${base_dir}/processing",
    "${base_dir}/properties",
    "${base_dir}/wget",
  ]

  $ro_dirs = [
    "${base_dir}/${bin_dir_name}",
    "${base_dir}/${script_dir_name}",
  ]

  $exec_path = [
    $ro_dirs,
    "/usr/bin",
    "/bin",
  ]

  $deploy_freq = "*/5"

  $date_command = '`/usr/bin/date \+\%Y-\%m-\%d`'
  $cron_command = "${base_dir}/bin/deploymgr.sh >> ${base_dir}/logs/deploymgr.log.${date_command} 2>&1"
  $version_regexp = '\d+\.\d+\.\d+'


}
