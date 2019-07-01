# Daedalus::Core
Information system which also manages all other services, clients, organizations and projects.

**Master**
[![pipeline master status](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/badges/master/pipeline.svg)](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/commits/master)[![gitlab master coverage report](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/badges/master/coverage.svg)](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/commits/master)
**Develop**
[![pipeline develop status](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/badges/develop/pipeline.svg)](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/commits/develop)[![gitlab develop coverage report](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/badges/develop/coverage.svg)](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/commits/develop)
## Running tests

### Local computer

Environment variable *APP_TEST* must exists and be set to *1*.

```
rm META.yml ; rm -f /var/tmp/daedalus_core_realms.db && perl script/daedalus_core_deploy.pl SQLite /var/tmp/daedalus_core_realms.db && perl t/script/populate_test_database.pl &&  perl Makefile.PL && make && make test
```
