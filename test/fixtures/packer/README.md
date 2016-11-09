# Websphere Cookbook

## Baking the websphere media ami

Travis-ci currently has a hard 50min build timeout. For this reason, and because we want to speed up integration tests anyway, we need to pre-bake the websphere media into the ami used in test-kitchen tests.

Unfortunately because of websphere licensing this is only relevant for Sainsburys employees.

You will need:
1. The travis-ci.pem private key before you can run packer.
2. AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY env variables set for relevant aws account.
3. ibm passport advantage creds set in PASSPORTADV_USER and PASSPORTADV_PW
4. dependant cookbooks like build-essential in ~/.berkshelf/cookbooks


The packer build will:
1. make the root partition expandable to allow for > 10GB.
2. install chef (still need to update chef provisioner to not use chef-zero not solo)
3. yum update
4. run websphere-test::was_media recipe, which downloads the was media from s3.

```bash
cd test/fixtures/packer
./bake_test_ami.sh
```
