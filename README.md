# X-Road Message Log Archive S3 Transfer

Script and corresponding credential templates for transferring X-Road Message Log archive files to an AWS S3 bucket (based on the X-Road message log package [archive-http-transporter.sh](https://github.com/nordic-institute/X-Road/blob/develop/src/addons/messagelog/scripts/archive-http-transporter.sh) script).  This script also synchronises the X-Road Security Server configuration backup files to the bucket.

- As a user with `sudo` permissions, execute the following script to install the AWS CLI tool:
```
./install-aws-cli.sh
```

- As the operating system user running the X-Road server (commonly `xroad`), deploy configuration and credentials files for the CLI tool in the users's home directory with the following commands:
```
mkdir -p ~/.aws
cp config ~/.aws/
cp credentials ~/.aws/
```

- Edit the `~/.aws/credentials` file and populate the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` for the bucket to be used.

- Deploy the archive transfer script:
```
./deploy-archive-transfer-script.sh
```

- Edit `/etc/xroad/conf.d/local.ini` and add the following:
```
[message-log]
archive-transfer-command=/usr/share/xroad-archive-transfer/archive-s3-transporter.sh -r <bucket-name>
```
or if backup files should be synchronized, along with the transfer of message log archive files, the command would be like:
```
[message-log]
archive-transfer-command=/usr/share/xroad-archive-transfer/archive-s3-transporter.sh -s -r <bucket-name>
```
  where `<bucket-name>` is the name of the bucket where achive and backup files are to be stored.

- Apply the X-Road configuration by issuing:
```
systemctl restart xroad-proxy
```
