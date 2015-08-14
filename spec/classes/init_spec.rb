require 'spec_helper'

def should_contain_dir(name, owner)
  should contain_file(name).with(
    "ensure" => "directory",
    "owner"  => owner,
    "group"  => owner,
    "mode"   => "0644", # puppet promotes to 0755 on filesystem but RSpec cannot detect this
  )
end

def should_contain_rw_dir(name)
  should_contain_dir(name, "wsadmin")
end

def should_contain_file(path, name)
  should contain_file("#{path}/#{name}").with(
    "ensure" => "file",
    "owner"  => "wsadmin",
    "group"  => "wsadmin",
    "mode"   => "0755",
    "source" => "puppet:///modules/websphere_deployer/#{name}"
  )
end

def should_contain_script(name)
  should_contain_file("/opt/ibm/deployments/scripts", name)
end

def should_contain_bin(name)
  should_contain_file("/opt/ibm/deployments/bin", name)
end

describe 'websphere_deployer' do

  let :params do
    {
      "gem_provider" => "puppet_gem"
    }
  end

  # successful compilation
  context "compile minimal" do
    it do
      expect { should compile }.not_to raise_error
    end
  end


  # directories created
  context "directories created" do
    it do
      should_contain_rw_dir("/opt/ibm/deployments")
      should_contain_rw_dir("/opt/ibm/deployments/error")
      should_contain_rw_dir("/opt/ibm/deployments/incoming")
      should_contain_rw_dir("/opt/ibm/deployments/logs")
      should_contain_rw_dir("/opt/ibm/deployments/processed")
      should_contain_rw_dir("/opt/ibm/deployments/processing")
      should_contain_rw_dir("/opt/ibm/deployments/properties")
      should_contain_rw_dir("/opt/ibm/deployments/wget")
      should_contain_rw_dir("/opt/ibm/deployments/bin")
      should_contain_rw_dir("/opt/ibm/deployments/scripts")
    end
  end

  # script/bin files installed
  context "scripts installed" do
    it do
      should_contain_script("restartAppServer.sh")
      should_contain_script("startAppServer.sh")
      should_contain_script("stopAppServer.sh")
      should_contain_script("was_deploy.py")
      should_contain_bin("env.sh")
      should_contain_bin("deploymgr.sh")
    end
  end

  # cron ensure on
  context "cron ensure present" do
    it do
      should contain_cron("websphere_deploymgr").with(
        "ensure" => "present",
      )
    end
  end

  # cron ensure off
  context "cron ensure absent" do
    let :params do
      {
        "cron_ensure" => "absent"
      }
    end
    it do
      should contain_cron("websphere_deploymgr").with(
        "ensure" => "absent",
      )
    end
  end

end
