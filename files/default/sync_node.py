import sys
node = sys.argv[0] # all, or node name

def syncNodes(nodeName):
   nodeSync = AdminControl.completeObjectName('type=NodeSync,node=' + nodeName + ',*')
   AdminControl.invoke(nodeSync, 'sync')

def syncAllNodes():
   for node in AdminConfig.list('Node').splitlines():
      syncNodes(AdminConfig.showAttribute(node, 'name'))

if (node == 'all'):
    syncAllNodes()
else:
    syncNodes(node)
