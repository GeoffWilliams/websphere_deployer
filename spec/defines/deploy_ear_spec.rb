require 'spec_helper'
describe 'websphere_deployer::deploy_ear', :type => :define do

  # global default facts
  let :facts do
    {
      :wsapp_instance_appnames => {
        "test" => "test",
      },
      :wsapp_versions => {
        "test" => {
          "version" => "6.6.6",
        }
      },
    }
  end

  # global default title
  let :title do
    "http://foo.com/file-ear-2.1.0.ear"
  end

  # global default parameters
  let :params do
    {
      :deployment_instance => "test",
    }
  end

  # include the params class before running tests
  let :pre_condition do
    'class { "websphere_deployer::params": }'
  end

  # minimal compilation
  context "compile minimal" do
    it do
      expect { should compile }.not_to raise_error
    end
  end

  # MD5 checksum comparison
  context "md5 remote checksum" do
    it do
      expect {should compile}.not_to raise_error

      should contain_archive("/opt/ibm/deployments/incoming/test.ear").with(
        "ensure"        => "present",
        "extract"       => false,
        "source"        => "http://foo.com/file-ear-2.1.0.ear",
        "checksum_url"  => "http://foo.com/file-ear-2.1.0.ear.md5",
        "checksum_type" => "md5",
        "user"          => "wsadmin",
        "group"         => "wsadmin",
      )
    end
  end

  # Unversioned files are not allowed
  context "unversioned download" do
    let :title do
      "http://foobar.com/ear-foofile.ear"
    end
    it do
      expect { should compile }.to raise_error(/ersion/)

    end
  end

  # service correctly registered (so we can refer to in from corp_properties DRT
  #context "service correctly registered" do
  #  it do
  #    expect {should compile}.not_to raise_error      
  #
  #    should contain_exec("was_service_test").with(
  #      "refreshonly" => true,
  #    )
  #  end
  #end


  # Only upgrade when different version is supplied
  context "no upgrade because same version" do
    let :title do
      "http://foo.com/file-ear-6.6.6.ear"
    end
    it do
      expect {should compile}.not_to raise_error

      should_not contain_archive("/opt/ibm/deployments/incoming/test.ear")
    end
  end

  # error on missing facter value to resolve instance_name -> appname
  context "error if deployment_instance -> appName mapping in facter missing" do
    let :facts do
      {
        :wsapp_instance_appnames => {},
        :wsapp_versions => {
          "test" => {
            "version" => "6.6.6",
          }
        },
      }
    end
    it do
      expect {should compile}.to raise_error(/facter.*wsapp_instance_appnames\[test\]/)
    end
  end


  # if no version info present, we should install the app
  context "new install succeeds" do
    let :facts do
      {
        :wsapp_instance_appnames => {
          "test" => "test",
        },
        :wsapp_versions => {},
      }
    end
    it do
      expect {should compile}.not_to raise_error

      # just check catalogue entry exists, parameters checked already      
      should contain_archive("/opt/ibm/deployments/incoming/test.ear")
    end
  end

  # error on missing facter value to resolve version info for appname
  context "incomplete facter data must fail" do
    let :facts do
      {
        :wsapp_instance_appnames => {
          "test" => "test",
        },

        # notice version key is missing...
        :wsapp_versions => {
          "test" => {},
        },
      }
    end
    it do
      expect {should compile}.to raise_error(/there is no version number.  You cannot use this tool/)
    end    
  end

end
