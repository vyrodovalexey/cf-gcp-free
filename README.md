## CloudFoundry deployment on GCP free



### Usage

1. Login to CF

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

