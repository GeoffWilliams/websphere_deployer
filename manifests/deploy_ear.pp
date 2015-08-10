define websphere_deployer::deploy_ear(
  $deployment_instance,
  $download_url,
  $app_server,
  $incoming_dir = "/opt/ibm/deployment/incoming",
  $user         = "wsadmin",
  $group        = "wsadmin",
) {

  $safe_name = strip($deployment_instance)

  $app_name = ws_properties[$safe_name]

  # ws_app_versions["TRACE HVCORS EAR"]=2.5.2


  $final_file = "$incoming_dir/${deployment_instance}.ear"
  $deployment_instance_version = regexpmatch($download_url)


  # surrogate service resource
  exec { "was_service_${title}":
    command => "restartAppServer ${app_server}",
    refreshonly => true,
  }


  if $ws_app_versions[$deployment_instance] != $deployment_instance_version {
  
    archive { $final_file:
      ensure        => present,
      extract       => false,
      source        => $download_url,
      checksum      => '2ca09f0b36ca7d71b762e14ea2ff09d5eac57558',
      checksum_type => 'md5',
      user          => $user,
      group         => $group,
    }
  }


}
