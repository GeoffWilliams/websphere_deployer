define websphere_deployer::deploy_props(
    $ensure                 = present,
    $additional_emails      = false,
    $app_name               = false,
    $app_servers            = false,
    $cell                   = false,
    $cluster                = false,
    $context_root           = false,
    $cookie_path            = false,
    $deploy_env_jsp         = false,
    $deploy_ws              = false,
    $ear_path               = false,
    $host                   = false,
    $parent_first           = false,
    $restart_app_servers    = false,
    $security_role_mapping  = false,
    $stop_app_servers       = false,
    $properties_dir         = $websphere_deployer::properties_dir,
    $exec_path              = $websphere_deployer::exec_path,
    $user                   = $websphere_deployer::user,
    $group                  = $websphere_deployer::group,
) {

  $target_file  = "${properties_dir}/${title}.properties"
  $exec_service = "wsapp_service_${title}"

  # Equivalent to a service resource
  exec { $exec_service:
    path        => $exec_path,
    command     => "restartAppServer.sh ${app_servers}",
    refreshonly => true,
  }


  file { $target_file:
    ensure  => $ensure,
    owner   => $user,
    group   => $group,
    mode    => "0440",
    content => template("${module_name}/deploy.properties.erb"),
    notify  => Exec[$exec_service],
  }
}
