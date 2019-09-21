# `trombik.grafana`

Install `grafana`.

# Requirements

None

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `grafana_user` | user of `grafana` | `{{ __grafana_user }}` |
| `grafana_group` | group of `grafana` | `{{ __grafana_group }}` |
| `grafana_log_dir` | path to log directory | `{{ __grafana_log_dir }}` |
| `grafana_db_dir` | path to database directory | `{{ __grafana_db_dir }}` |
| `grafana_plugins_dir` | path to plug-in directory | `{{ grafana_db_dir }}/plugins` |
| `grafana_service` | service name of `grafana` | `{{ __grafana_service }}` |
| `grafana_conf_dir` | path to configuration directory | `{{ __grafana_conf_dir }}` |
| `grafana_conf_file` | path to configuration file | `{{ grafana_conf_dir }}/grafana.ini` |
| `grafana_provisioning_dir` | path to provisioning directory | `{{ grafana_conf_dir }}/provisioning` |
| `grafana_package` | package name of `grafana` | `{{ __grafana_package }}` |
| `grafana_extra_packages` | extra packages to install | `[]` |
| `grafana_flags` | | `""` |
| `grafana_plugins` | list of plug-ins to install | `[]` |
| `grafana_admin_user` | administration user name | `""` |
| `grafana_admin_password` | administration user's password | `""` |
| `grafana_config` | content of `grafana.ini` | `""` |
| `grafana_provisioning_files` | see below | `[]` |

## `grafana_provisioning_files`

This variable manages files under `grafana_provisioning_dir` (see
[Provisioning Grafana](https://grafana.com/docs/administration/provisioning/)
for details. It is a list of dict, whose keys and values are described below.

| Key name  | Value                                                                  | Mandatory? |
|-----------|------------------------------------------------------------------------|------------|
| `name`    | relative path to the provisioning file from `grafana_provisioning_dir` | Yes        |
| `state`   | either `present` or `absent`                                           | No         |
| `content` | the content of the provisioning file                                   | No         |

An example:

```
grafana_provisioning_files:
  - name: datasources/influxdb.yml
    state: present
    content: |
      apiVersion: 1
      datasources:
        - name: InfluxDB
          type: influxdb
          access: proxy
          database: mydatabase
          user: read
          password: read
          url: http://localhost:8086
          jsonData:
            httpMode: GET
  - name: datasources/foo.yml
    state: absent
```

## Debian

| Variable | Default |
|----------|---------|
| `__grafana_user` | `grafana` |
| `__grafana_group` | `grafana` |
| `__grafana_log_dir` | `/var/log/grafana` |
| `__grafana_db_dir` | `/var/lib/grafana` |
| `__grafana_service` | `grafana-server` |
| `__grafana_conf_dir` | `/etc/grafana` |
| `__grafana_package` | `grafana` |

## FreeBSD

| Variable | Default |
|----------|---------|
| `__grafana_user` | `grafana` |
| `__grafana_group` | `grafana` |
| `__grafana_log_dir` | `/var/log/grafana` |
| `__grafana_db_dir` | `/var/db/grafana` |
| `__grafana_service` | `grafana` |
| `__grafana_conf_dir` | `/usr/local/etc` |
| `__grafana_package` | `www/grafana5` |

# Dependencies

None

# Example Playbook

```yaml
---
- hosts: localhost
  roles:
    - name: trombik.apt_repo
      when: ansible_os_family == 'Debian'
    - ansible-role-grafana
  vars:
    apt_repo_keys_to_add:
      - https://packages.grafana.com/gpg.key
    apt_repo_enable_apt_transport_https: yes
    apt_repo_to_add:
      - "deb https://packages.grafana.com/oss/deb stable main"
    grafana_extra_packages:
      - name: zsh
    grafana_plugins:
      - name: raintank-worldping-app
        state: present
      - name: grafana-clock-panel
        state: absent
    flags:
      FreeBSD: |
        grafana_conf="{{ grafana_conf_file }}"

    grafana_flags: "{{ flags[ansible_os_family] }}"
    grafana_admin_user: admin
    grafana_admin_password: PassWord
    grafana_addr: "{{ ansible_default_ipv4['address'] }}"
    grafana_provisioning_files:
      - name: datasources/influxdb.yml
        state: present
        content: |
          apiVersion: 1
          datasources:
            - name: InfluxDB
              type: influxdb
              access: proxy
              database: mydatabase
              user: read
              password: read
              url: http://localhost:8086
              jsonData:
                httpMode: GET
    grafana_config: |
      [paths]
      data = {{ grafana_db_dir }}
      logs = {{ grafana_log_dir }}
      plugins = /var/db/grafana/plugins
      provisioning = {{ grafana_provisioning_dir }}
      [server]
      [database]
      log_queries =
      [session]
      [dataproxy]
      [analytics]
      [security]
      admin_user = {{ grafana_admin_user }}
      admin_password = {{ grafana_admin_password }}
      disable_gravatar = true
      [snapshots]
      [dashboards]
      [users]
      [auth]
      [auth.anonymous]
      [auth.github]
      [auth.google]
      [auth.generic_oauth]
      [auth.grafana_com]
      [auth.proxy]
      [auth.basic]
      [auth.ldap]
      [smtp]
      [emails]
      [log]
      [log.console]
      [log.file]
      [log.syslog]
      [alerting]
      [metrics]
      [metrics.graphite]
      [tracing.jaeger]
      [grafana_com]
      [external_image_storage]
      [external_image_storage.s3]
      [external_image_storage.webdav]
      [external_image_storage.gcs]
      [external_image_storage.azure_blob]
      [external_image_storage.local]
```

# License

```
Copyright (c) 2018 Tomoyuki Sakurai <y@trombik.org>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <y@trombik.org>

This README was created by [qansible](https://github.com/trombik/qansible)
