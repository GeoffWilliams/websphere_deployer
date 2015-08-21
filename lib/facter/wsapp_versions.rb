# Parse version info from pom.xml in deployed applications.  Would have been
# nice to use a real XML parser here but:
# a) we are on solaris so can't rely on packages being installed/installable
# b) gem doesn't seem to work properly behind proxies so we can't install nokogiri
# c) nokogiri never installs properly without installing half the internet and a C compiler
# ... therefore we will process as dumb strings.  Infact, why not go for the
# jugular, lets use awk
#
# ... Ok, here's why not - we're on solaris and it doesn't work properly - or 
# at least not in the way I expect it to.  Our only real option is to read the
# file with ruby and process each line - YUK!

def parse_xml(tag_name, data)
  value = "NOT_FOUND"

  # regexp to both match the line and replace with whitespace
  tag = /<\/?#{tag_name}>/
  
  data.each do | line |
    if line =~ tag then
      # remove the tag
      value = line.strip().gsub(tag, "")

      # break us out of this loop - we have found what we are looking for
      break
    end
  end    
  return value
end

Facter.add("wsapp_versions") do
  wsapp_versions = {}
  Dir.glob("/opt/ibm/WebSphere/AppServer/profiles/AppSrv*/installedApps/*/*.ear/META-INF/maven/*/*/pom.xml").each do |path|
 
    # the application name can only be obtained from the path to the pom.xml
    # file.  EG /opt/ibm/WebSphere/AppServer/profiles/AppSrv01/installedApps/Cell01/opr EAR.ear/opr-webapp-4.2.0.war/META-INF/maven/nswrta.opr/opr-webapp/
    # needs to be translated to `opr EAR`.  This can be done by splitting on 
    # `/` and eliminating the .ear extension
    name        = path.split("/")[9].gsub(/\.ear$/i, "")

    data        = IO.readlines(path)
    
    version     = parse_xml("version", data)
    group_id    = parse_xml("groupId", data)
    artifact_id = parse_xml("artifactId", data)
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
