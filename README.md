# Daedalus::Core
Information system which also manages all other services, clients, organizations and projects.

**Master**
[![pipeline master status](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/badges/master/pipeline.svg)](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/commits/master)[![gitlab master coverage report](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/badges/master/coverage.svg)](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/commits/master)
**Develop**
[![pipeline develop status](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/badges/develop/pipeline.svg)](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/commits/develop)[![gitlab develop coverage report](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/badges/develop/coverage.svg)](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/commits/develop)

## Running tests

### Local Environment

Environment variable *APP_TEST* must exists and be set to *1*.

``` bash
rm META.yml ; 
rm -f /var/tmp/daedalus_core_realms.db
perl script/daedalus_core_deploy.pl SQLite /var/tmp/daedalus_core_realms.db
perl t/script/DatabaseSetUpTearDown.pm
perl Makefile.PL
make
make test
```

Run server
```
perl script/daedalus_core_server.pl
```

API server will be available in http://0.0.0.0:3000

### Quick curl tests

```
time curl -X POST "https://api-dev.daedalus-project.io/user/login" -H  "accept: application/json" -H  "Content-Type: application/json" -d '{"password":"this_is_a_Test_1234","e-mail":"admin@daedalus-project.io"}'
```

## Model management

Create model from database:
```bash
perl script/daedalus_core_create.pl model CoreRealms  DBIC::Schema Daedalus::Core::Schema::CoreRealms create=static overwrite_modifications=true "dbi:mysql:daedalus_core_realms:localhost:3306" your_user your_password
```
