# Install corporate (app+server) specific properties file
#
# Params
# [*title*]
#   Full path to file to write properties out to or arbitrary string if both
#   this attribute and `target_file` are specified
# [*props_hash*]
#   Hash of properties to write out to file.  These should be simple 
#   key => value pairs
# [*ensure*]
#   Set present or absent to create/destroy the file respectively
# [*user*]
#   Properties file owner, restricted to a system-wide value in 
#   `websphere_deployer` for consistency
# [*group*]
#   Propeties file group, restricted to a system-wide value in 
#   `websphere_deployer` for consistency
# [*target_file*]
#   Complete file path to properties file to write.  Defaults to `title`
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

