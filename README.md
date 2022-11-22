# Puppet Mimir

Puppet module for Mimir management.

## Table of Contents

- [Puppet Mimir](#puppet-mimir)
  - [Table of Contents](#table-of-contents)
  - [Description](#description)
  - [Setup](#setup)
    - [Setup Requirements](#setup-requirements)
    - [Install and configure Mimir](#install-and-configure-mimir)
    - [Customize configuration](#customize-configuration)
  - [Related](#related)
  - [License](#license)

## Description

This module manages:
* Software installation (with the use of apt).
* Main configuration
* Systemd overrides
* logging to file

## Setup

### Setup Requirements

This module has three dependencies:
* [Stdlib](https://forge.puppet.com/modules/puppetlabs/stdlib)
* [Systemd](https://forge.puppet.com/modules/camptocamp/systemd)
* [Logrotate](https://forge.puppet.com/modules/puppet/logrotate)

### Install and configure Mimir

Simply call the main class in a Puppet manifest:

```puppet
class{'mimir': }
```

### Customize configuration

This module allows every parameter to be customized via hiera, or via class
instantiation.

You can, for instance, change interactive mode timeout to 30 seconds:

```puppet
class {'mimir':
      config_hash => {
        target => 'querier',
      },
}
```

You can consult [REFERENCE.md](REFERENCE.md) file for a complete list of
available parameters.


## Related

* [Mimir](https://grafana.com/oss/mimir/)

## License

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
