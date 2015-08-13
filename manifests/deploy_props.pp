# Create/remote deployment properties files under /opt/ibm/deployer/properties
#
# Params
# ======
# [*ensure*]
#   Ensure the properties file is present (default) or absent
# [*additional_emails*]
#   Value to munge into properties file
# [*app_name*]
#   Value to munge into properties file
# [*app_servers*]
#   Value to munge into properties file
# [*cell*]
#   Value to munge into properties file
# [*cluster*]
#   Value to munge into properties file
# [*context_root*]
#   Value to munge into properties file
# [*cookie_path*]
#   Value to munge into properties file
# [*deploy_env_jsp*]
#   Value to munge into properties file
# [*deploy_ws*]
#   Value to munge into properties file
# [*ear_path*]
#   Value to munge into properties file
# [*host*]
#   Value to munge into properties file
# [*parent_first*]
#   Value to munge into properties file
# [*restart_app_servers*]
#   Value to munge into properties file
# [*security_role_mapping*]
#   Value to munge into properties file
# [*stop_app_servers*]
#   Value to munge into properties file
# [*properties_dir*]
#   Directory to store properties files in.  System-wide setting in 
#   `websphere_deployer` for consistency
# [*exec_path*]
#   Path used for exec resource used to restart services.  System-wide setting
#   in `websphere_deployer` for consistency
# [*user*]
#   Properties file owner, restricted to a system-wide value in 
#   `websphere_deployer` for consistency
# [*group*]
#   Propeties file group, restricted to a system-wide value in 
#   `websphere_deployer` for consistency
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
