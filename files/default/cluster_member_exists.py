import sys

def listServersInCluster(clusterName):
    clusterId = AdminConfig.getid("/ServerCluster:" + clusterName + "/")
    clusterMembers = _splitlines(AdminConfig.list("ClusterMember", clusterId ))
    return clusterMembers

def _splitlines(s):
  rv = [s]
  if '\r' in s:
    rv = s.split('\r\n')
  elif '\n' in s:
    rv = s.split('\n')
  if rv[-1] == '':
    rv = rv[:-1]
  return rv

clusterName = sys.argv[0]
print clusterName
nodeName = sys.argv[1]
print nodeName
serverName = sys.argv[2]
print serverName
clusterMembers = listServersInCluster(clusterName)
is_found = 0 
for clusterMember in clusterMembers:
  clusterNodeName = AdminConfig.showAttribute( clusterMember, "nodeName" )
  if clusterNodeName == nodeName:
    clusterServerName = AdminConfig.showAttribute( clusterMember, "memberName" )
    if clusterServerName == serverName:
      is_found = 1
print "===%s===" % (is_found)
