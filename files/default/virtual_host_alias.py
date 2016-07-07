# this script manages virtual hosts.

import sys

if len(sys.argv) < 4:
  print "Missing arguments. \n Usage: virtual_hosts.py <action> <alias_host> <alias_port>.  \n Action must be add_alias or remove_alias."
  sys.exit(1)

action = sys.argv[0]  # can be add_alian or remove_alias
vhost = sys.argv[1]
alias_host = sys.argv[2]
alias_port = sys.argv[3]

def addVirtualHostAlias(virtualHostName, alias):
  virtualHost = AdminConfig.getid("/VirtualHost:" + virtualHostName)
  print "adding vhost alias " + virtualHost + " alias_host: " + alias[0] + " port: " + alias[1]
  AdminConfig.create("HostAlias", virtualHost, [["hostname", alias[0]], ["port", alias[1]]])

def removeVirtualHostAlias(virtualHostName, alias):
  virtualHost = AdminConfig.getid("/VirtualHost:" + virtualHostName)
  for a in toList(AdminConfig.showAttribute(virtualHost, 'aliases')):
    if AdminConfig.showAttribute(a, 'hostname') == alias[0] and AdminConfig.showAttribute(a, 'port') == alias[1]:
      print "removing vhost alias " + virtualHost + " alias_host: " + alias[0] + " port: " + alias[1]
      AdminConfig.remove(a)

def virtualHostExists(virtualHostName):
    for vh in toList(AdminConfig.list("VirtualHost")):
        if AdminConfig.showAttribute(vh, "name") == virtualHostName:
            return 1
    return 0

def aliasExists(virtualHostName, alias):
    for vh in toList(AdminConfig.list("VirtualHost")):
      if AdminConfig.showAttribute(vh, "name") == virtualHostName:
        for al in toList(AdminConfig.showAttribute(vh, 'aliases')):
            if AdminConfig.showAttribute(al, 'hostname') == alias[0] and AdminConfig.showAttribute(al, 'port') == alias[1]:
                return 1
    return 0

def toList(inStr):
    outList=[]
    if (len(inStr)>0 and inStr[0]=='[' and inStr[-1]==']'):
        inStr = inStr[1:-1]
        tmpList = inStr.split(" ")
    else:
        tmpList = inStr.split("\n")
    for item in tmpList:
        item = item.rstrip();
        if (len(item)>0):
           outList.append(item)
    return outList

if action == 'add_alias':
  if virtualHostExists(vhost)==1 and aliasExists(vhost, [alias_host, alias_port])==0:
    addVirtualHostAlias(vhost, [alias_host, alias_port])
    AdminConfig.save()
  else:
    print "vhost doesn't exist, or alias already exists"
elif action == 'remove_alias':
  if aliasExists(vhost, [alias_host, alias_port]):
    removeVirtualHostAlias(vhost, [alias_host, alias_port])
    AdminConfig.save()
else:
  print "Missing is mismatched action paramater. Action must be add_alias or remove_alias. \n Usage: virtual_hosts.py <action> <alias_host> <alias_port>"
