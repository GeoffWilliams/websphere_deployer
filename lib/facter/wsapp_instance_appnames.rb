# Use awk to read the appName field from the properties files
require 'shellwords'
def appname(file)
  command = "awk 'BEGIN {FS=\"=\"} /appName/  { print $2 ; exit }' < '#{Shellwords.escape(file)}'"
  return Facter::Core::Execution.exec(command)
end

Facter.add("wsapp_instance_appnames") do
  webapps_dir = "/opt/ibm/tree"
  app_names = {}
  Dir.glob("/opt/ibm/deployments/properties/*.properties").each do |path|
    name = File.basename(path).sub(".properties", "")

    app_names[name] = appname(path)
  end
  setcode do 
    app_names
  end
end
