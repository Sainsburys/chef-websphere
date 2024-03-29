IBM Websphere Cookbook CHANGELOG
========================

v1.2.4
--------------------

- add provides to the LWRPs to allow them to work in Chef 16+
- do not require `dn` as a parameter for `ibm_cert` as this isn't required for the `add`/`extract`/`import` etc. actions
- add GitHub Action CI checks

v1.2.3
--------------------

- cookstyle fixes and unit test updates

v1.2.2
--------------------

- Fix incorrect call for dependent services breaking federation.

v1.2.1
--------------------

- Allow dependent services e.g. node agents to start first.

v1.2.0
--------------------

- Add multiple cluster members in a single wsadmin update, rather than separate calls for each.

v1.1.4
--------------------

- Bug fix for `websphere_base`:`get_cluster_members` function, did not return successful output previously

v1.1.3
--------------------

- Bug fix for `websphere_base`:`enable_as_service` function

v1.1.2
--------------------

- Enhance SystemD operations and make it more generic

v1.1.1
--------------------

- Add Systemd services for Deployment Manager and Node Agent

v1.1.0
--------------------

- Chef 13 deprecation fixes
- Additional unit tests for IBM certificate library
- Add a timeout option for Deployment Manager start

v1.0.13
--------------------

- Update Gem dependencies

v1.0.12
--------------------

- Change Deployment Manager init script to use startManager.sh and stopManager.sh
- Allow use of environment variables with the dmgr profile

v1.0.11
--------------------

- update README docs with WAS ND 7.0

v1.0.10
--------------------

- use pure wsadmin to determine cluster membership

v1.0.9
--------------------

- add ability to specify a template for new cluster member

v1.0.8
--------------------

- Don't add a new cluster template if one exists

v1.0.7
--------------------

- Update to allow setting of attributes against a JMS provider

v1.0.6
--------------------

- Fix fingerprint call and make update more idempotent (and faster)

v1.0.5
--------------------

- add update action for IBM certificate import

v1.0.4
--------------------

- add user parameter to commands so files are not owned by root in contexts where we are running as user

v1.0.3
--------------------

- ensure server members with the same name on different nodes do not clash on cluster member checks
- add group setting to certain commands

v1.0.2
--------------------

- use cookstyle for style check
- fix integration tests(IBMCMSKS provider missing)
- do not try to look at the current java sdk if the attribute is not specified (WAS ND 7 Friendly)
- allow to not create a user and a service when using websphere_profile

v1.0.1
--------------------
- run manageprofiles.sh as was run_user
- add sensitive_exec feature for debugging on all resources
- readme update

v1.0.0
--------------------

- released to supermarket. Travis-ci integration tests.

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
