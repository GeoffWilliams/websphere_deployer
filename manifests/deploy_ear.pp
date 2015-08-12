# Download an ear file to the websphere server if version number obtained from
# the download URL indicates that we need to change versions vs the current
# system version
#
# Params
# [*title*]
#   File to download or arbitrary string if `download_url` also specified
# [*deployment_instance*]
#   Instance to deploy to.  Used to find out information about the deployment
#   server by inspecting a properties file at 
#   `/opt/ibm/deployments/properties/${deployment_instance}.properties`
# [*incoming dir*]
#   Directory to save `.ear` files to.  The cron job will detect these files
#   and deploy them if present
# [*user*]
#   User who runs the cron job, also used for file ownership
# [*group*]
#   Used for file ownership for websphere-writable files
# [*version_regexp*]
#   Regular expression used to validate version numbers captured from the
#   download URL via regular expression=
# [*exec_path*]
#   Default path to use for `Exec` resources
# [*disable_md5*]
#   If true, do not attempt to verify the md5 sum of remote files
define websphere_deployer::deploy_ear(
  $deployment_instance,
  $download_url   = $title,
  $incoming_dir   = $websphere_deployer::incoming_dir,
  $user           = $websphere_deployer::user,
  $group          = $websphere_deployer::group,
  $version_regexp = $websphere_deployer::version_regexp,
  $exec_path      = $websphere_deployer::exec_path,
  $disable_md5    = false,
) {
  
  if $disable_md5 {
    $checksum_url  = undef
    $checksum_type = undef
  } else {
    $checksum_url  = "${download_url}.md5"
    $checksum_type = "md5"
  }


  if has_key($::wsapp_instance_appnames, $deployment_instance) {
    $app_name = $::wsapp_instance_appnames[$deployment_instance]
  } else {
    fail("No facter data for wsapp_instance_appnames[${deployment_instance}]")
  }
  $final_file = "${incoming_dir}/${deployment_instance}.ear"
  
  # Capture the version number from the bit of the filename between ear-... and .ear
  $deployment_instance_version = regsubst($download_url, '.*?ear-(.+).ear', '\1')
    
  # surrogate service resource.  always created but only fired via the 
  # corp_properties DRT (yet to be written)
 
  # FIXME this logic is broken. we talk about restarting a whole app server but refernce the instance...
  # resolve via properties file: 
  #exec { "was_service_${deployment_instance}":
  #  path        => $exec_path,
  #  command     => "restartAppServer ${app_server}",
  #  refreshonly => true,
  #}


  if $deployment_instance_version =~ $version_regexp {
    if has_key($::wsapp_versions, $app_name) and has_key($wsapp_versions[$app_name], "version") {
      $installed_version = $wsapp_versions[$app_name]["version"]
    } elsif has_key($::wsapp_versions, $app_name) and ! has_key($wsapp_versions[$app_name], "version") {
      fail("Facter data exists for wsapp_versions[${app_name}] but there is no version number.  You cannot use this tool")
    } else {
      # no version information available, force installation
      $installed_version = "-1"
    } 
    
    if $installed_version != $deployment_instance_version {
    
      archive { $final_file:
        ensure        => present,
        extract       => false,
        source        => $download_url,
        checksum_url  => $checksum_url,
        checksum_type => $checksum_type,
        user          => $user,
        group         => $group,
      }
    }
  } else {
    fail("No version matching ${version_regexp} could be parsed from '${deployment_instance_version}' (from ${download_url})")
  }

}
