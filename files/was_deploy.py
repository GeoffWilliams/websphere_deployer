# Jython script to install a EAR or WAR in WebSphere Application Server
# Usage: /opt/ibm/WebSphere/AppServer/bin/wsadmin.sh -lang jython -f was_deploy.py sample.properties

import sys
import java.util
import java.io
from org.python.modules import time

LINE_SEPARATOR = java.lang.System.getProperty('line.separator')

numberOfArgs = len(sys.argv)
if numberOfArgs < 1:
    print "Usage: was_deploy.py {app-property-file-path}"
    sys.exit(0)
    
appPropertiesFile = str(sys.argv[0])    

input =java.io.FileInputStream(appPropertiesFile) 

props = java.util.Properties()
props.load( input) 
input.close()

def isClusterRunning(clusterName):
    clusterObject = AdminControl.completeObjectName("type=Cluster,name="+clusterName+",*" )
    clusterStatus = AdminControl.getAttribute(clusterObject, "state" )
    
    print "clusterStatus=", clusterStatus  
    
    return cmp(clusterStatus, "websphere.cluster.running") == 0
        
def syncNodes():
    nodes = AdminControl.queryNames("WebSphere:type=NodeSync,*").split()
    for node in nodes:
        AdminControl.invoke(node, "sync")
        #print node
#

# this will parse out the values for a webserver into a dictionary (map) that we can use
# in multiple places
def getCellNodeAndServer(wasString):
        # parse out the part between the first open bracket and the pipe
        subStr = wasString[wasString.find("(")+1:wasString.find("|")]
        tokens = subStr.split("/")

        # values out of the string
        values = {}
        values['cell'] = tokens[1]
        values['node'] = tokens[3]
        values['server'] = tokens[5]

        return values

#this will take a string like the following:
# WebDev01(cells/DevCell/nodes/NodeDev01/servers/WebDev01|server.xml#WebServer_1153749486049)
# and turn it into something like:
# WebSphere:cell=DevCell,node=NodeDev01,server=WebDev01
def buildWasString(wasString):
        # get the map of values
        values = getCellNodeAndServer(wasString)

        return "WebSphere:cell=" + values['cell'] + ",node=" + values['node'] + ",server=" + values['server']


# this builds up the argument for mapping the cluster AND the webservers
# to a web module
def getMapToServerArgument(cluster):
    arg = getClusterFullName(cluster)

    webservers = AdminConfig.list('WebServer').split()
    for webserver in webservers:
        arg = arg + "+" + buildWasString(webserver)

    return arg



# this will grab the cluster object, figure out the correct string that is needed
# to map (or remap) an app to this cluster
def getClusterFullName(cluster):
    fullName = AdminControl.completeObjectName("type=Cluster,name=" + cluster + ",*")
    prefixRemoved = fullName[fullName.find(":")+1:]

    # extract the cell and node info we need
    for pairs in prefixRemoved.split(","):
        pair = pairs.split("=")
        key = pair[0]
        value = pair[1]
        if ("cell" == key):
            return "WebSphere:cell=" + value + ",cluster=" + cluster

# this will return a list of the cluster members for the given cluster
def getClusterMembers(config, cluster):
    members = []
    cluster_id = config.getid( '/ServerCluster:'+ cluster)
    for clusterMember in config.list('ClusterMember', cluster_id).split(LINE_SEPARATOR):
        members.append(clusterMember[:clusterMember.find("(")])
    return members

# this will actually change the deployment
def mapAppToWebServers(appName, cluster):
    option = [[".*", ".*", getMapToServerArgument(cluster)]]
    mapWebModuleOption = ["-MapModulesToServers", option]
    AdminApp.edit(appName, mapWebModuleOption)

def getWebModule(config, applicationName):
    webModules = config.list('WebModuleDeployment').split(LINE_SEPARATOR)
    for webModule in webModules:
        if (webModule.find("/" + applicationName + "|") != -1):
            return webModule
    return None

cell = props.getProperty('cell').strip()
#node = props.getProperty('node').strip()

appName = props.getProperty('appName').strip()

earPath = props.getProperty('earPath').strip()

contextRoot = props.getProperty('contextRoot')

parentFirst = props.getProperty('parentFirst') == "True"

cluster = props.getProperty('cluster').strip()

deployWS = props.getProperty('deployWS') == 'True'

host = props.getProperty('host')

cookiePath = props.getProperty('cookiePath')

secrolemap = props.getProperty('SecurityRoleMapping') == 'True'

#webserver = props.getProperty('webserver')

#install application
apps = AdminApp.list().split(LINE_SEPARATOR);
for app in apps:
    theAppName = str(app).strip()

    if cmp(theAppName,appName) == 0:
        print "Uninstall:",  theAppName
        AdminApp.uninstall(theAppName)
        AdminConfig.save()
        break
        
#options = "-defaultbinding.virtual.host " + host
#options = options + " -usedefaultbindings"

#if deployWS:
#    options = options + " -deployws"

#options = options + " -appname " + '\"' + appName + '\"'

#options = options + " -cluster " + '\"' + cluster + '\"'

#if (contextRoot):
#    options = options + " -contextroot /" + contextRoot.strip()
    
#options = "[" + options + "]"

options = []

options.append("-defaultbinding.virtual.host")
options.append(host)

options.append("-usedefaultbindings")

if deployWS:
    options.append("-deployws")    

options.append("-appname")
options.append(appName)

options.append("-cluster")
options.append(cluster)

options.append("-cell")
options.append(cell)

if (contextRoot):
    options.append("-CtxRootForWebMod")
    options.append([['.*', '.*', contextRoot]])
    
print "options:", options
print "install:", appName

AdminApp.install(earPath, options)

print "map web module"
mapAppToWebServers(appName, cluster)

AdminConfig.save()

print '--- Applcaiton Installed ---'

if secrolemap:
    print '---security role mapping---'
    AdminApp.edit(appName,'[-MapRolesToUsers[["Customer" No No "" "" Yes "" ""]]]')
    print AdminApp.view(appName,['-MapRolesToUsers'])

print '--- Set classpath loader ---'
#set classpath loader
deployment= AdminConfig.getid('/Deployment:' + appName + '/')
deployedObject = AdminConfig.showAttribute(deployment, "deployedObject")
classloader = AdminConfig.showAttribute(deployedObject, 'classloader')

if parentFirst:
    AdminConfig.modify(classloader, [['mode', 'PARENT_FIRST']])
else:
    AdminConfig.modify(classloader, [['mode', 'PARENT_LAST']])

AdminConfig.modify(deployedObject, [['warClassLoaderPolicy', 'SINGLE']])

AdminConfig.save()

modules = AdminConfig.showAttribute(deployedObject, 'modules')
print "---------modules---------"
print modules

webModule = getWebModule(AdminConfig, appName)
if (webModule != None):
    if parentFirst:
        AdminConfig.modify(webModule, "[[classloaderMode PARENT_FIRST]]")
    else:
        AdminConfig.modify(webModule, "[[classloaderMode PARENT_LAST]]")
    AdminConfig.save()
    
    webModuleClassLoader = AdminConfig.showAttribute(webModule,'classloaderMode')
    print "Webmodule class loader", webModuleClassLoader
else:
    print "Error: Cannot find web module for application: " + appName
    
print '--- Configure Session Management ---'
deployment= AdminConfig.getid('/Deployment:' + appName + '/')
deployedObject = AdminConfig.showAttribute(deployment, 'deployedObject')

overrideSessionManagement = ['enable', 'true']


tuningParm1 = ['invalidationTimeout', 30]
tuningParams = ['tuningParams', [tuningParm1]]

cookiePathAttr = ['path', cookiePath] 
cookieAttr = [cookiePathAttr] 
cookieSettings = ['defaultCookieSettings', cookieAttr] 

sessionMgrAttrs = [overrideSessionManagement, cookieSettings, tuningParams]

sessionMgr = [['sessionManagement', sessionMgrAttrs]]

id = AdminConfig.create('ApplicationConfig', deployedObject, sessionMgr, 'configs')

targetMappings = AdminConfig.showAttribute(deployedObject, 'targetMappings')

delimiter = " "
if targetMappings[1:len(targetMappings)-1].find('"') != -1:
    delimiter = '"'
        
targetMappings = targetMappings[1:len(targetMappings)-1].split(delimiter)

for target in targetMappings:
    if target.find('DeploymentTargetMapping') != -1:
        attrs = ['config', id]
        AdminConfig.modify(target,[attrs])

AdminConfig.save()

#print '--- Start Applicaiton ---'

isAppReady = AdminApp.isAppReady(appName)
while (isAppReady == 'false'):
    time.sleep(60)
    isAppReady = AdminApp.isAppReady(appName)



#if isClusterRunning(cluster):
#    clusterMembers = getClusterMembers(AdminConfig, cluster)
#    for clusterMember in clusterMembers:
#        appManager = AdminControl.queryNames('process='+ clusterMember +',type=ApplicationManager,*')
#        AdminControl.invoke(appManager, 'startApplication', '\"' + appName + '\"')
#    
#    print "Application installed and started successfuly!", java.util.Date() 
#else:
#    print "Cluster ", cluster, 'not running' 
#    print "Application installed!", java.util.Date() 
    
print "sync nodes"
syncNodes()

print "Application installed!", java.util.Date() 
