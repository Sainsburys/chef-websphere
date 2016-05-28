# this script outputs a dictionary of all nodes, servers and their endpoints.

import sys
import re
if len(sys.argv) > 0:
    serverName = sys.argv[0]
else:
    serverName = ''

matcher = '/ServerEntry:%s/' % (serverName)
servers = AdminConfig.getid(matcher).splitlines()
# servers = AdminConfig.list( 'ServerEntry' ).splitlines()
print "==="
json = "{ "
endpoints = {}
for server in servers :
    serverName = server[0:server.find('(')]
    match = re.search('nodes\/(.*?)\|', server)
    nodeName = match.group(1)
    # initialize node key if it hasn't been already
    if endpoints.get(nodeName, None) == None:
        endpoints[nodeName] = {}
    # add server key
    endpoints[nodeName].update({ serverName : {} })
    # append server endpoints to server
    NamedEndPoints = AdminConfig.list( "NamedEndPoint" , server).splitlines()
    for namedEndPoint in NamedEndPoints:
        endPointName = AdminConfig.showAttribute(namedEndPoint, "endPointName" )
        endPoint = AdminConfig.showAttribute(namedEndPoint, "endPoint" )
        host = AdminConfig.showAttribute(endPoint, "host" )
        port = AdminConfig.showAttribute(endPoint, "port" )
        endpoints[nodeName][serverName].update({ endPointName : { 'host': host, 'port': port } })
print endpoints
print "==="
