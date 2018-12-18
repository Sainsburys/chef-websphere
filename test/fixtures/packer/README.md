# WebSphere Cookbook

## Baking the WebSphere media AMI

Travis-CI currently has a hard 50min build timeout. For this reason, and because we want to speed up integration tests anyway, we need to pre-bake the WebSphere media into the AMI used in Test-Kitchen tests.

Unfortunately due to WebSphere licensing constraints, this is only relevant for Sainsbury's employees.

You will need:

1. The travis-ci.pem private key before you can run Packer.
2. `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` env variables set for relevant AWS account.
3. IBM Passport Advantage credentials set in `PASSPORTADV_USER` and `PASSPORTADV_PW`
4. dependent cookbooks like build-essential in `~/.berkshelf/cookbooks`

The packer build will:

1. make the root partition expandable to allow for > 10GB.
2. install Chef (still need to update Chef provisioner to use chef-zero not solo)
3. yum update
4. run the `websphere-test::was_media` recipe, which downloads the WAS media from S3.

```bash
cd test/fixtures/packer
./bake_test_ami.sh
```
