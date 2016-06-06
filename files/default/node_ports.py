import java
import sys
import re
if len(sys.argv) == 2:
   nodeName = sys.argv[0]
   serverName = sys.argv[1]
elif len(sys.argv) == 1:
   nodeName = sys.argv[0]
else:
   nodeName = ''
   serverName = ''

lineSeparator = java.lang.System.getProperty('line.separator')

# get Node
nodeMatcher = '/Node:%s/Server:%s' % (nodeName, serverName)
serverIDs = AdminConfig.getid(nodeMatcher)
arrayServerIDs = serverIDs.split(lineSeparator)

# get Ports
EndPointIDs = AdminConfig.getid('/EndPoint:/')
arrayEndPointIDs = EndPointIDs.split(lineSeparator)
NamedEndPointIDs = AdminConfig.getid('/NamedEndPoint:/')
arrayNamedEndPointIDs = NamedEndPointIDs.split(lineSeparator)

# print
for x in range(len(arrayNodeIDs)):
        for y in range(len(arrayEndPointIDs)):
                if arrayEndPointIDs[y].find(AdminConfig.showAttribute(arrayNodeIDs[x],'name')) > 0:
                        print '[[%s,%s]]' % (AdminConfig.showAttribute(arrayNamedEndPointIDs[y],'endPointName'), AdminConfig.showAttribute(arrayEndPointIDs[y],'port'))

                #endIf
        #endFor - Endpoints by ID
#endFor - Nodes by ID
