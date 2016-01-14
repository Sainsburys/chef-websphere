import java
import sys
nodeName = sys.argv[0]
nodeName = '' if nodeName.nil?
lineSeparator = java.lang.System.getProperty('line.separator')

# get Node
nodeMatcher = '/Node:%s/' % (nodeName)
NodeIDs = AdminConfig.getid(nodeMatcher)
arrayNodeIDs = NodeIDs.split(lineSeparator)

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
