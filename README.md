### Bypassing GCP free trial quota to install CloudFoundry.

### Usage

1. Singup on Google GCP

2. Installing Cloud SDK and git on your PC and install requirements
https://cloud.google.com/sdk/downloads
```
sudo apt-get install mc htop net-tools build-essential ruby wget git apt-transport-https -y
```
3. Enable GCP API services and create Storage access key

4. Login to GCP
```
gcloud auth login
```

5. Creating IAM service account
```
gcloud iam service-accounts create cf-user --display-name "CF"
```
6. Create service keys
Set your PROJECT_ID
```
gcloud iam service-accounts keys create --iam-account='cf-user@PROJECT_ID.iam.gserviceaccount.com' \
cf-user.key.json
```

7. Adding editor role
Set your PROJECT_ID
```
gcloud projects add-iam-policy-binding PROJECT_ID \
--member='serviceAccount:cf-user@PROJECT_ID.iam.gserviceaccount.com' \
--role='roles/editor'

gcloud projects add-iam-policy-binding PROJECT_ID \
--member='serviceAccount:cf-user@PROJECT_ID.iam.gserviceaccount.com' \
--role='roles/datastore.owner'

gcloud projects add-iam-policy-binding PROJECT_ID \
--member='serviceAccount:cf-user@PROJECT_ID.iam.gserviceaccount.com' \
--role='roles/cloudsql.admin'
```

8. Turning on SQL Cloud API
https://console.developers.google.com/apis/api/sqladmin.googleapis.com/overview?project=590574243243

9. Downloading Terraform v0.9.1 or later. Unzip the file and move it to somewhere in your PATH:

```
tar xvf ~/Downloads/terraform*
sudo mv ~/Downloads/terraform /usr/local/bin/terraform
```

10. Exporting GCP credetials and PROJECT_ID
```
export TF_CREDS=~/cf-user.key.json
export GOOGLE_CREDENTIALS=$(cat ${TF_CREDS})
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

11. Cloning cf-gcp-free
```
git clone https://github.com/vyrodovalexey/cf-gcp-free.git
```

12. Preparing network environment.
Change values project, domains, domain, user_sql, user_sql_password
```
cd cf-gcp-free
terraform init
```
```
terraform plan -var project=PROJECT_ID -var domains='["*.app.example.com","*.ws.example.com.info","*.example.com.info"]' \
-var domain=example.com -var user_sql=USER -var user_sql_password=PASSWORD
```
```
terraform plan -var project=PROJECT_ID -var domains='["*.app.example.com","*.ws.example.com.info","*.example.com.info"]' \
-var domain=example.com -var user_sql=USER -var user_sql_password=PASSWORD
```
```
cd ..
```
13. Setup DNS
Check IP of LB (LoadBalancer) in GCP and setup your DNS zone.
LB_IP *.app.example.com
LB_IP *.ws.example.com
LB_IP *.example.com





14. Deploying BOSH
14.1. Installing utility
```
wget https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.45-linux-amd64
chmod +x bosh-cli-2.0.45-linux-amd64
sudo mv bosh-cli-2.0.45-linux-amd64 /usr/local/bin/bosh
```

14.2. Cloning bosh repo
```
git clone https://github.com/cloudfoundry/bosh-deployment
```
14.3. Deploying Director
Change PROJECT_ID
```
bosh create-env bosh-deployment/bosh.yml \
--state=state.json \
--vars-store=creds.yml \
-o bosh-deployment/jumpbox-user.yml \
-o bosh-deployment/gcp/cpi.yml \
-v director_name=bosh-director \
-v internal_cidr=10.0.0.0/24 \
-v internal_gw=10.0.0.1 \
-v internal_ip=10.0.0.6 \
--var-file gcp_credentials_json=~/cf-user.key.json \
-v project_id=PROJECT_ID \
-v zone=us-central1-a \
-v tags=[bosh-director] \
-v network=default \
-v subnetwork=cfnet \
-o bosh-deployment/gcp/gcs-blobstore.yml \
-v bucket_name=bosh_gcp_PROJECT_ID \
--var-file director_gcs_credentials_json=~/cf-user.key.json \
--var-file agent_gcs_credentials_json=~/cf-user.key.json \
-o bosh-deployment/uaa.yml \
-o bosh-deployment/credhub.yml \
-o cf-gcp-free/bosh-director-ephemeral-ip-ops.yml
```

14.4. Configuring BOSH env gcp
```
bosh -e BOSH_IP alias-env gcp --ca-cert <(bosh int creds.yml --path /director_ssl/ca)
```
```
bosh int creds.yml --path /director_ssl/ca > bosh.crt
export BOSH_CA_CERT=bosh.crt
export BOSH_ENVIRONMENT=https://IP_BOSH_DIRECTOR:25555
```

14.5. Obtain generated admin password
```
bosh int creds.yml --path /admin_password
```

14.6. Login
```
bosh -e gcp login
Email (): admin
Password ():
```

14.7. Uploading latest stemcell
http://bosh.cloudfoundry.org/stemcells/
Example:
```
wget  https://s3.amazonaws.com/bosh-core-stemcells/google/bosh-stemcell-3468.15-google-kvm-ubuntu-trusty-go_agent.tgz
bosh -e gcp upload-stemcell bosh-stemcell-3468.15-google-kvm-ubuntu-trusty-go_agent.tgz
```

Check
```
bosh -e gcp stemcells
```

14.8. Updating cloud-config
```
bosh -e gcp update-cloud-config cf-gcp-free/cloud-config.yml
```

15. Deploying Cloudfoundry

15.1. Cloning repo
```
git clone https://github.com/cloudfoundry/cf-deployment.git
```

15.2. Preparing vars files.

Set actual values into files below (cf-gcp-free direcory)
vars-use-external-dbs.yml
vars-use-gcs-blobstore.yml

User and password for DB take from section 12.
Take IP for DB from GCP console.

Access key was created in section 3.
Take bucket names from GCP console.


15.3. Deploying
```
bosh -e gcp -d cf deploy cf-deployment/cf-deployment.yml --vars-file cf-gcp-free/vars-use-external-dbs.yml \
--vars-file cf-gcp-free/vars-use-gcs-blobstore.yml --vars-store env-repository/deployment-vars.yml \
-o cf-gcp-free/cf-gcp-free.yml \
-o cf-deployment/operations/use-external-dbs.yml \
-o cf-deployment/operations/use-gcs-blobstore.yml \
-v system_domain=example.com
```



15.4. Installing cf utility
```
echo "deb http://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
```
```
wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
```
```
sudo apt-get update
sudo apt-get install cf-cli
```

15.5. Login

Getting CF admin password
```
cat env-repository/deployment-vars.yml | grep cf_admin_password
```

login
```
cf login -a api.example.com --skip-ssl-validation
API endpoint: api.pcf.myitnotes.info

Email> admin

Password>
Authenticating...
OK

Targeted org system



API endpoint:   https://api.pcf.myitnotes.info (API version: 2.100.0)
User:           admin
Org:            system
Space:          No space targeted, use 'cf target -s SPACE'
```

15.6. Creating org and space
```
cf create-org TEST
cf target -o "TEST"
cf create-space DEV
cf target -o "TEST" -s "DEV"
```

15.7. Cloning test repo
```
git clone https://github.com/krujos/cf-hello-world-sample-apps.git
```

15.8. Starting test app
```
cd cf-hello-world-sample-apps/php
cf push phpexample
```

If you will see following:
```
Starting app phpexample in org TEST / space DEV as admin...
FAILED
Error restarting application: Server error, status code: 502, error code: 0, message:
```

That's ok. Just wait few minutes and try to open in browser. (Wait some)

http://phpexample.example.com

15.9. Starting docker

To enable Docker support, run:
```
cf enable-feature-flag diego_docker
```
To start docker example, run:
```
cf push my-app --docker-image mrbarker/python-flask-hello
```
If you will see following:
```
Starting app my-app in org TEST / space DEV as admin...
FAILED
Error restarting application: Server error, status code: 502, error code: 0, message:
```

That's ok. Just wait few minutes and try to open in browser. (Wait some)

http://my-app.example.com

##To be continued...

## Enjoy!

