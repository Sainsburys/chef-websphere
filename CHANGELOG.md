IBM Websphere Cookbook CHANGELOG
========================

v0.6.0
--------------------
- new websphere env variable resource.

v0.5.2
--------------------
- fix bug when adding a cert that's already in keystore.

v0.5.1
--------------------
- p12 keystores allowed in ibm_cert resource

v0.5.0
--------------------
- new app server resource

v0.4.1
--------------------
- fix bug in jms regex check if exists.
- jms resource fix to avoid custom resource variable scope conflicts.

v0.4.0
--------------------
- new resources for jms destination and jms connection factory. Integration tests for all jms resources.

v0.3.3
--------------------
- cleaner bugfix for starting webserver after it has just been created to allow time to propagate.

v0.3.2
--------------------
- bugfix for starting webserver after it has just been created to allow time to propagate.

v0.3.1
--------------------
- bugfix for federating and existing node that isn't yet federated.

v0.3.0
--------------------
- added vhost_alias resource
- added another sync_node option that doesn't restart nodeagent or servers
- changed extract_cert default filename extension to .cer

v0.2.0
--------------------
- added websphere_wsadmin resource for convenience
- added jms_provider resource
- added ibm_cert resource

v0.1.0
--------------------
- added sync_node feature
- added save config for some changes.
- added start_all_servers in node
- fixed cluster ripplestart and added cluster startSingleServer and stop
- bug fix for libgcc.i686 conflict version with libgcc

v0.0.6
--------------------
- get_ports function to set server endpoints as attributes.
- change logging from warn to debug to reduce noise

v0.0.5
--------------------
- Change default was root to /opt/IBM/WebSphere/Appserver
- add save to various wsadmin commands.

v0.0.4
--------------------
- minor update to ihs integration tests

v0.0.3
--------------------
- bug fix for when security attributes=nil
- add berksfile.lock ot gitignore
- getports.py bug fix

v0.0.2
--------------------
- added global application security property change
