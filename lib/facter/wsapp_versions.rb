# Parse version info from pom.xml in deployed applications.  Would have been
# nice to use a real XML parser here but:
# a) we are on solaris so can't rely on packages being installed/installable
# b) gem doesn't seem to work properly behind proxies so we can't install nokogiri
# c) nokogiri never installs properly without installing half the internet and a C compiler
# ... therefore we will process as dumb strings.  Infact, why not go for the
# jugular, lets use awk
require 'shellwords'

def parse_xml(field, file)
  field_safe  = Shellwords.escape(field)
  file_safe   = Shellwords.escape(file)
  command = "awk 'BEGIN {FS=\"<|>\"} /#{field}/ { print $3 ; exit }' < #{file_safe}"
  return Facter::Core::Execution.exec(command)
end

Facter.add("wsapp_versions") do
  wsapp_versions = {}
  Dir.glob("/opt/ibm/WebSphere/AppServer/profiles/AppSrv*/installedApps/*/*.ear/META-INF/maven/*/*/pom.xml").each do |path|
# ignore name from pom.xml - could potentially be different to the real app name
# crap - we can't ignore it! we need to use as a key... we don't read this in puppet
# code though and can probably get this from hiera in the future
    name        = parse_xml("<name>", path)
    version     = parse_xml("<version>", path)
    group_id    = parse_xml("<groupId>", path)
    artifact_id = parse_xml("<artifactId>", path)
    wsapp_versions[name] = {
      "groupId"    => group_id,
      "artifactId" => artifact_id,
      "version"    => version,
    }
  end
  setcode do 
    wsapp_versions
  end
end
