require 'spec_helper'

def regexp_in_file(filename, regexp) 
  should contain_file(filename).with_content(regexp)
end

def regexp_not_in_file(filename, regexp)
  should contain_file(filename).without_content(regexp)
end

$props_file = "/opt/ibm/deployments/properties/test.properties"

describe 'websphere_deployer::deploy_props', :type => :define do

  # global default title
  let :title do
    "test"
  end

  # global default parameters
  let :params do
    {
    }
  end

  # include the params class before running tests
  let :pre_condition do
    'class { "websphere_deployer": 
       gem_provider => "puppet_gem",
     }'
  end

  # minimal compilation
  context "compile minimal" do
    it do
      expect { should compile }.not_to raise_error
    end
  end

  # parameters munged into template correctly
  context "parameters present in template" do
    let :params do
      {
        "additional_emails"     => "value_additional_emails",
        "app_name"              => "value_app_name",
        "app_servers"           => "value_app_servers",
        "cell"                  => "value_cell",
        "cluster"               => "value_cluster",
        "context_root"          => "value_context_root",
        "cookie_path"           => "value_cookie_path",
        "deploy_env_jsp"        => "value_deploy_env_jsp",
        "deploy_ws"             => "value_deploy_ws",
        "ear_path"              => "value_ear_path",
        "host"                  => "value_host",
        "parent_first"          => "value_parent_first",
        "restart_app_servers"   => "value_restart_app_servers",
        "security_role_mapping" => "value_security_role_mapping",
        "stop_app_servers"      => "value_stop_app_servers",
      }
    end
    it do

      regexp_in_file($props_file, /additionalEmails=value_additional_emails/)
      regexp_in_file($props_file, /appName=value_app_name/)
      regexp_in_file($props_file, /appServers=value_app_servers/)
      regexp_in_file($props_file, /cell=value_cell/)
      regexp_in_file($props_file, /cluster=value_cluster/)
      regexp_in_file($props_file, /contextRoot=value_context_root/)
      regexp_in_file($props_file, /cookiePath=value_cookie_path/)
      regexp_in_file($props_file, /deployEnvJSP=value_deploy_env_jsp/)
      regexp_in_file($props_file, /deployWS=value_deploy_ws/)
      regexp_in_file($props_file, /earPath=value_ear_path/)
      regexp_in_file($props_file, /host=value_host/)
      regexp_in_file($props_file, /parentFirst=value_parent_first/)
      regexp_in_file($props_file, /restartAppServers=value_restart_app_servers/)
      # always capitalised in props files ATM... guessing this was an accident
      regexp_in_file($props_file, /[sS]ecurityRoleMapping=value_security_role_mapping/)
      regexp_in_file($props_file, /stopAppServers=value_stop_app_servers/)
    end
  end

  # changed properties cause appserver to be restarted
  context "restart app server on props change" do
    

    it do
      should contain_file($props_file).that_notifies('Exec[wsapp_service_test]') 
    end
  end

end
