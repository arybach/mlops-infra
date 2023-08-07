### install vault
https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-install?in=vault%2Fgetting-started#getting-started-install

GPG is required for the package signing key
$ sudo apt update && sudo apt install gpg

Download the signing key to a new keyring
$ wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

Verify the key's fingerprint
$ gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint

The fingerprint must match 798A EC65 4E5C 1542 8C8E 42EE AA16 FCBC A621 E701, which can also be verified at https://www.hashicorp.com/security under "Linux Package Checksum Verification". Please note that there was a previous signing key used prior to January 23, 2023, which had the fingerprint E8A0 32E0 94D8 EB4E A189 D270 DA41 8C88 A321 9F7B. Details about this change are available on the status page: https://status.hashicorp.com/incidents/fgkyvr1kwpdh, https://status.hashicorp.com/incidents/k8jphcczkdkn.

Add the HashiCorp repo
$ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

apt update!
$ sudo apt update

To see all available packages, you can run: grep ^Package: /var/lib/apt/lists/apt.releases.hashicorp.com*Packages | sort -u

Install a product
$ sudo apt install consul
$ sudo apt install vault

check:
$ vault
$ vault status

### set secrets manually via ui 
https://dev.to/aws-builders/deploying-iac-with-your-secrets-in-terraform-vault-4ggc

### or for use in dev environemt use local vault server
start server if not running
$ vault server -dev -dev-root-token-id="environment"

WARNING! dev mode is enabled! In this mode, Vault runs entirely in-memory
and starts unsealed with a single unseal key. The root token is already
authenticated to the CLI, so you can immediately begin using Vault.

You may need to set the following environment variables:

    $ export VAULT_ADDR='http://127.0.0.1:8200'

The unseal key and root token are displayed below in case you want to
seal/unseal the Vault or re-authenticate.

Unseal Key: bXXXXXXXXXXXXXXXXXXXXXXEXXXX=
Root Token: environment

Development mode should NOT be used in production installations!

then go to http://127.0.0.1:8200 
* click on secrets
* add secret
* add path: /aws
* enable: json
* copy and paste the following json updated with your own keys:

{
"AWS_ACCESS_KEY_ID":"xxxxxxxxxxxxxxx",
"AWS_SECRET_ACCESS_KEY":"xxxxxxxxxxxxxxxxxxx",
"AWS_REGION":"xxxxxxxxxxxxxxxxxxxx",
"OPENAI_API_KEY":"xxxxxxxxxxxxxxxxxxxx",
"HUGGING_FACE_TOKEN":"xxxxxxxxxxxxxxxxxxxx",
"USDA_API_KEY":"xxxxxxxxxxxxxxxxxxxx"
}

*  save - keep vault server running locally

### add to bashrc if using proper root tokens and unseal keys
add to ~/.bashrc
export VAULT_ADDR=https://<vault_server_address>:8200
export VAULT_TOKEN=<vault_access_token>
$ source ~/.bashrc

### remove elastic.pem from git and when running terraform apply again

### ec2 instance clones this repo to launch ELK
git clone --branch tls https://github.com/deviantony/docker-elk.git

specify your passwords in .env file before creating the resource
if any changes to default docker-compose file are needed uncomment provisioner file to pass your own version

### full instructions
https://github.com/deviantony/docker-elk/tree/tls#bringing-up-the-stack

elasticsearch should be running on remote_machine_ip:9200 and kibana should be accessable on remote_machine_ip:5601 port (password in .env file)
if kibana is not running use elastic.pem file to ssh into remote machine and check logs
ssh -i elastic.pem ec2-user@remote_machine_ip
docker-compose down
docker-compose up
should be sufficient unless security group blocks access to ports