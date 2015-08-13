define websphere_deployer::deploy_props(
    $ensure                 = present,
    $additional_emails      = "",
    $app_name               = "",
    $app_servers            = "",
    $cell                   = "",
    $cluster                = "",
    $context_root           = "",
    $cookie_path            = "",
    $deploy_env_jsp         = "",
    $deploy_ws              = "",
    $ear_path               = "",
    $host                   = "",
    $parent_first           = "",
    $restart_app_servers    = "",
    $security_role_mapping  = "",
    $stop_app_servers       = "",
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
