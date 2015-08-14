require 'spec_helper'

def regexp_in_file(filename, regexp) 
  should contain_file(filename).with_content(regexp)
end

def regexp_not_in_file(filename, regexp)
  should contain_file(filename).without_content(regexp)
end

$props_file = "/tmp/test.properties"

describe 'websphere_deployer::corp_props', :type => :define do

  # global default title
  let :title do
    $props_file
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
        "props_hash" => {
          "aaaaaa.webgway.jmsConnectionFactory.brokerURL" => "tcp://localhost:61616",
          "aaaaaa.webgway.sftg.agency.codes"              => "3000,3001",
          "aaaaaa.webgway.batch.schedule.date.format"     => "yyMMddHHmm"
        }
      }
    end
    it do
      regexp_in_file($props_file, /aaaaaa.webgway.jmsConnectionFactory.brokerURL=tcp:\/\/localhost:61616/)
      regexp_in_file($props_file, /aaaaaa.webgway.sftg.agency.codes=3000,3001/)
      regexp_in_file($props_file, /aaaaaa.webgway.batch.schedule.date.format=yyMMddHHmm/)   
    end
  end

  # changed properties cause appserver to be restarted
  #context "restart app server on props change" do
  #  it do
  #    should contain_file($props_file).that_notifies('Exec[wsapp_service_test]') 
  #  end
  #end

end
