# Install corporate (app+server) specific properties file
define websphere_deployer::corp_props(
  $props_hash   = false,
  $ensure       = present,
  $user         = $websphere_deployer::user,
  $group        = $websphere_deployer::group,
  $target_file  = $title,
) {


  # fixme - need to work out what services to restart and then notify them...
  file { $target_file:
    ensure  => $ensure,
    owner   => $user,
    group   => $group,
    mode    => "0440",
    content => template("${module_name}/corp.properties.erb"),
  }

} 

