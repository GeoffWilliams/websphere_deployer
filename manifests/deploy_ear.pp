define websphere_deployer::deploy_ear(
  $deployment_instance,
  $download_url,
  $app_server   = $::fqdn,,
  $incoming_dir = "${websphere_deployer::params::base_dir}/incoming",
  $user         = $websphere_deployer::params::user,
  $group        = $websphere_deployer::params::user,
) inherits websphere_deployer::params {

  $safe_name = strip($deployment_instance)
  $md5_url = "${download_url}.md5"

  $app_name = ws_properties[$safe_name]

  # ws_app_versions["TRACE HVCORS EAR"]=2.5.2


  $final_file = "$incoming_dir/${deployment_instance}.ear"
  
  # Capture the version number from the bit of the filename between ear-... and .ear
  $deployment_instance_version = regsubst($download_url, '.*?ear-(.+).ear', '\1') 


  # surrogate service resource
  exec { "was_service_${title}":
    command => "restartAppServer ${app_server}",
    refreshonly => true,
  }


  if $ws_app_versions[$app_name]["version"] != $deployment_instance_version {
  
    archive { $final_file:
      ensure        => present,
      extract       => false,
      source        => $download_url,
      checksum_url  => $md5_url,
      checksum_type => 'md5',
      user          => $user,
      group         => $group,
    }
  }


}
