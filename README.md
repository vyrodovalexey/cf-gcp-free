### Bypassing GCP free trial quota to install CloudFoundry.


### Usage

1. Singup on Google GCP

2. Install Cloud SDK
https://cloud.google.com/sdk/downloads

3. Login to GCP
```
gcloud auth login
```

4. Create IAM service account
```
gcloud iam service-accounts create cf-user --display-name "CF"
```
5. Create service keys
Set your PROJECT_ID
```
gcloud iam service-accounts keys create --iam-account='cf-user@PROJECT_ID.iam.gserviceaccount.com' \
cf-user.key.json
```

6. Add editor role
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

7. Turn on SQL Cloud API
https://console.developers.google.com/apis/api/sqladmin.googleapis.com/overview?project=590574243243


8. Download Terraform v0.9.1 or later. Unzip the file and move it to somewhere in your PATH:

```
tar xvf ~/Downloads/terraform*
sudo mv ~/Downloads/terraform /usr/local/bin/terraform
```

9. Export GCP credetials
```
export TF_CREDS=~/cf-user.key.json
export GOOGLE_CREDENTIALS=$(cat ${TF_CREDS})
```

10. Create dir terraform
```
mkdir terraform
cd terraform
```

11*. Skip if certificate already exist. Create ssl domain wildcard certificate for loadbalancer. Domain example *.example.com
Put it to terraform directory
```
openssl genrsa -out example.key 2048
openssl req -new -key example.key -out example.csr
openssl x509 -req -days 365 -in example.csr -signkey example.key -out example.crt
```



12. Init terraform
```
terraform init
```

10. Prepare networks

Add following subnets to default network by using https://console.cloud.google.com:
cfnet	us-central1		10.0.0.0/24	10.0.0.1	On
cfnet1	southamerica-east1	10.0.1.0/24	10.0.1.1	On
cfnet2	asia-southeast1		10.0.2.0/24	10.0.2.1	On
cfnet3	australia-southeast1	10.0.3.0/24	10.0.3.1	On

8. Add firewall rule
Set your PROJECT_ID
```
gcloud compute --project=upbeat-cosine-188006 firewall-rules create bosh-external \
--allow tcp:22,tcp:6868,tcp:8443,tcp:8844,tcp:25555,tcp:4222,tcp:25250,tcp:25777 \
--source-tags=bosh-director,bosh-agent
```
```
gcloud compute --project=upbeat-cosine-188006 firewall-rules create bosh-cf-open --direction=INGRESS \
--priority=1000 --network=default --action=ALLOW --rules=tcp:443 --source-ranges=0.0.0.0/0 --target-tags=bosh-router-lb
```
```
gcloud compute --project=upbeat-cosine-188006 firewall-rules create bosh-cf-open --direction=INGRESS \
--priority=1000 --network=default --action=ALLOW --rules=tcp:443 --source-ranges=0.0.0.0/0 --target-tags=bosh-router-lb
```



gcloud compute firewall-rules create bosh-external \
--allow tcp:6868,tcp:8443,tcp:8844,tcp:25555,tcp:4222,tcp:25250,tcp:25777 \
--source-tags=bosh-director,bosh-agent
```

9. Static IP

```
gcloud compute --project=upbeat-cosine-188006 addresses create cf-static --region=australia-southeast1
```

10. Proxy
```
gcloud compute --project=upbeat-cosine-188006 target-tcp-proxies create cf-proxy --backend-service=BACKEND_SERVICE
```

gcloud beta compute --project "upbeat-cosine-188006" instance-templates create "instance-template-1" --machine-type "n1-standard-1" --network "default" --maintenance-policy "MIGRATE" --service-account "54397058921-compute@developer.gserviceaccount.com" --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --min-cpu-platform "Automatic" --image "debian-9-stretch-v20171213" --image-project "debian-cloud" --boot-disk-size "10" --boot-disk-type "pd-standard" --boot-disk-device-name "instance-template-1"

gcloud compute --project "upbeat-cosine-188006" instance-groups managed create "cf-tcp" --region "australia-southeast1" --base-instance-name "cf-tcp" --template "instance-template-1" --size "1"

gcloud compute --project "upbeat-cosine-188006" instance-groups managed set-autoscaling "cf-tcp" --region "australia-southeast1" --cool-down-period "60" --max-num-replicas "10" --min-num-replicas "1" --target-cpu-utilization "0.6"


9. Deploy BOSH
```
git clone https://github.com/cloudfoundry/bosh-deployment
```
change disk type in ./bosh-deployment/gcp/cpi.yml

# Configure sizes
- type: replace
  path: /resource_pools/name=vms/cloud_properties?
  value:
    zone: ((zone))
    machine_type: n1-standard-1
    root_disk_size_gb: 20
    root_disk_type: pd-ssd

Add blob bucket in gcp
Add segment in US-CENTRAL1 and bucket with name bosh_gcp


# Fill below variables (replace example values) and deploy the Director
Deploy Director
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
--var-file gcp_credentials_json=~/bbl-user.key.json \
-v project_id=upbeat-cosine-188006 \
-v zone=us-central1-a \
-v tags=[bosh-director] \
-v network=default \
-v subnetwork=cfnet \
-o bosh-deployment/gcp/gcs-blobstore.yml \
-v bucket_name=bosh_gcp \
--var-file director_gcs_credentials_json=~/bbl-user.key.json \
--var-file agent_gcs_credentials_json=~/bbl-user.key.json \
-o bosh-deployment/uaa.yml \
-o bosh-deployment/credhub.yml \
-o bosh-deployment/gcp/bosh-director-ephemeral-ip-ops.yml
```


  ```bash
  cf login -a https://api.run.pivotal.io
  ```

2. Clone the app (i.e. this repo).

  ```bash
  git clone https://github.com/vyrodovalexey/cf-postgresql-flask-example.git
  cd cf-postgresql-flask-example
  ```

3. If you don't have one already, create a Postgres service.  With Pivotal Web Services, the following command will create a free Postgres database through [ElephantSQL].

  ```bash
  cf create-service elephantsql turtle pgsql
  ```

4. Push it to CloudFoundry.

  ```bash
  cf push
  ```

5. Bind service to App.

  ```bash
  cf bind-service cf-postgresql-flask-example pgsql
  ```

6. Find potgresql requisits (username, host, database, password).  Just run this command and look for the VCAP_SERVICES environment variable under the `System Provided` section.

  ```bash
  cf env cf-postgresql-flask-example
  ```
  
7. Replace uname, password, host and database in cf-postgresql-flask-example.py

8. Push it again to CloudFoundry.
  ```bash
  cf push
  ```

## Enjoy!

