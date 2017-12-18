## CloudFoundry deployment on GCP free trial



### Usage

1. Singup on Google GCP

2. Install Cloud SDK
https://cloud.google.com/sdk/downloads

3. Create IAM service account
```gcloud iam service-accounts create bbl-user --display-name "BBL"
```
4. Create service keys
```gcloud iam service-accounts keys create --iam-account='bbl-user@upbeat-cosine-188006.iam.gserviceaccount.com' \
bbl-user.key.json
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

