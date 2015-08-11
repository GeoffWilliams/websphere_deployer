class websphere_deployer::params {
  $base_dir = "/opt/ibm/deployments"
  $user = "wsadmin"
  $group = "wsadmin"

  $script_files = [
    "restartAppServer.sh",
    "startAppServer.sh",
    "stopAppServer.sh,"
    "was_deploy.py"
  ] 


  $rw_dirs = [
    "${base_dir}/error",
    "${base_dir}/incoming",
    "${base_dir}/logs",
    "${base_dir}/processed",
    "${base_dir}/processing",
    "${base_dir}/properties",
    "${base_dir}/wget"
  ]

  $ro_dirs = [
    "${base_dir}/bin",
  ]

  $deploy_freq = "*/5"

  $cron_command = "${base_dir}/bin/deploymgr.sh >> ${base_dir}/logs/deploymgr.log.`/usr/bin/date \+\%Y-\%m-\%d` 2>&1"
}
