# Daedalus::Core
Information system which also manages all other services, clients, organizations and projects.

[![pipeline status](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/badges/master/pipeline.svg)](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/commits/master)[![coverage report](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/badges/master/coverage.svg)](https://git.daedalus-project.io/daedalusproject/Daedalus-Core/commits/master)[![Build Status](https://travis-ci.org/daedalusproject/Daedalus-Core.svg?branch=master)](https://travis-ci.org/daedalusproject/Daedalus-Core)[![Code Coverage](https://codecov.io/gh/daedalusproject/Daedalus-Core/branch/master/graph/badge.svg)](https://codecov.io/gh/daedalusproject/Daedalus-Core)

**Configuration**

*daedalus_core.conf*
```
name Daedalus::Core

<"Model::CoreRealms">
  schema_class Daedalus::Core::Schema::CoreRealms
    <connect_info>
      dsn dbi:mysql:database=daedalus_core_realms
      user USER
      password PASSWORD
      AutoCommit 1
    </connect_info>
</"Model::CoreRealms">
```
