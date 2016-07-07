IBM Websphere Cookbook CHANGELOG
========================

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
