include websphere_deployer
websphere_deployer::deploy_props { "test": 
  additional_emails     => "value_additional_emails",
  app_name              => "value_app_name",
  app_servers           => "value_app_servers",
  cell                  => "value_cell",
  cluster               => "value_cluster",
  context_root          => "value_context_root",
  cookie_path           => "value_cookie_path",
  deploy_env_jsp        => "value_deploy_env_jsp",
  deploy_ws             => "value_deploy_ws",
  ear_path              => "value_ear_path",
  host                  => "value_host",
  parent_first          => "value_parent_first",
  restart_app_servers   => "value_restart_app_servers",
  security_role_mapping => "value_security_role_mapping",
  stop_app_servers      => "value_stop_app_servers",
}
