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
| `grafana_conf_filename` | file name of configuration file | `{{ __grafana_conf_filename }}` |
| `grafana_conf_file` | path to configuration file | `{{ grafana_conf_dir }}/{{ grafana_conf_filename }}` |
| `grafana_provisioning_dir` | path to provisioning directory | `{{ grafana_conf_dir }}/provisioning` |
| `grafana_package` | package name of `grafana` | `{{ __grafana_package }}` |
| `grafana_extra_packages` | extra packages to install | `[]` |
| `grafana_flags` | | `""` |
| `grafana_plugins` | list of plug-ins to install | `[]` |
| `grafana_admin_user` | administration user name | `""` |
| `grafana_admin_password` | administration user's password | `""` |
| `grafana_config` | content of `grafana.ini` | `""` |
| `grafana_provisioning_files` | see below | `[]` |
| `grafana_provisioning_copy_files` | see below | `[]` |

## `grafana_provisioning_files`

This variable manages files under `grafana_provisioning_dir` (see
[Provisioning Grafana](https://grafana.com/docs/administration/provisioning/)
for details. It is a list of dict, whose keys and values are described below.

| Key name  | Value                                                                  | Mandatory? |
|-----------|------------------------------------------------------------------------|------------|
| `name`    | relative path to the provisioning file from `grafana_provisioning_dir` | Yes        |
| `state`   | either `present` or `absent`                                           | No         |
| `content` | the content of the provisioning file                                   | No         |
| `format`  | `yaml` is the only supported value at the moment. When the value is `yaml`, the value of `content` is parsed as YAML. Otherwise, the `content` is rendered as-is | No |

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

## `grafana_provisioning_copy_files`

This variable is a list of dict. The dict accepts all keys that
`ansible.builtin.copy` accepts.

In addition, it needs `state` as a key in the dict. `state` must be either
`present` or `absent`. When `present`, the role passes the dict to
`ansible.builtin.copy`. When `absent`, the file or the directory is removed.

The variable is useful when you want to provision dashboards from multiple
files. See the example.

## Debian

| Variable | Default |
|----------|---------|
| `__grafana_user` | `grafana` |
| `__grafana_group` | `grafana` |
| `__grafana_log_dir` | `/var/log/grafana` |
| `__grafana_db_dir` | `/var/lib/grafana` |
| `__grafana_service` | `grafana-server` |
| `__grafana_conf_dir` | `/etc/grafana` |
| `__grafana_conf_filename` | `grafana.ini` |
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
| `__grafana_conf_filename` | `grafana.ini` |
| `__grafana_package` | `www/grafana6` |

## OpenBSD

| Variable | Default |
|----------|---------|
| `__grafana_user` | `_grafana` |
| `__grafana_group` | `_grafana` |
| `__grafana_log_dir` | `/var/log/grafana` |
| `__grafana_db_dir` | `/var/grafana` |
| `__grafana_service` | `grafana` |
| `__grafana_conf_dir` | `/etc/grafana` |
| `__grafana_conf_filename` | `config.ini` |
| `__grafana_package` | `grafana` |

## RedHat

| Variable | Default |
|----------|---------|
| `__grafana_user` | `grafana` |
| `__grafana_group` | `grafana` |
| `__grafana_log_dir` | `/var/log/grafana` |
| `__grafana_db_dir` | `/var/lib/grafana` |
| `__grafana_service` | `grafana-server` |
| `__grafana_conf_dir` | `/etc/grafana` |
| `__grafana_conf_filename` | `grafana.ini` |
| `__grafana_package` | `grafana` |

# Dependencies

None

# Example Playbook

```yaml
---
- hosts: localhost
  roles:
    - name: trombik.redhat_repo
      when:
        - ansible_os_family == 'RedHat'
    - name: trombik.apt_repo
      when: ansible_os_family == 'Debian'
    - name: trombik.telegraf
    - name: trombik.influxdb
    - name: trombik.nginx
    - name: ansible-role-grafana
  vars:

    grafana_extra_packages:
      - name: zsh
    grafana_plugins:
      - name: raintank-worldping-app
        state: present
      - name: grafana-clock-panel
        state: absent
    os_grafana_flags:
      FreeBSD: |
        grafana_conf={{ grafana_conf_file }}
      OpenBSD: ""
      Debian: ""

    grafana_flags: "{{ os_grafana_flags[ansible_os_family] }}"
    grafana_admin_user: admin
    grafana_admin_password: password
    grafana_addr: "{{ ansible_default_ipv4['address'] }}"
    grafana_provisioning_files:
      - name: datasources/influxdb.yml
        state: present
        format: yaml
        content:
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

      - name: dashboards/default.yml
        # an example to provision dashboards with grafana_provisioning_files
        state: present
        # raw text
        content: |
          # Managed by ansible
          apiVersion: 1
          providers:
            - name: a unique provider name
              orgId: 1
              folder: Test folder
              type: file
              disableDeletion: true
              editable: true
              updateIntervalSeconds: 10
              options:
                path: {{ grafana_provisioning_dir }}/dashboards/json

      - name: dashboards/copy.yml
        # an example to provision dashboards with grafana_provisioning_copy_files
        state: present
        # raw text
        content: |
          # Managed by ansible
          apiVersion: 1
          providers:
            - name: copy
              orgId: 1
              type: file
              folder: ""
              disableDeletion: true
              editable: true
              updateIntervalSeconds: 10
              options:
                path: {{ grafana_provisioning_dir }}/dashboards/copy
                foldersFromFilesStructure: true
      - name: dashboards/json/example.json
        # XXX when looking up a json file, the return value is escaped so that
        # the value is valid YAML string. you need `from_json | to_nice_json`
        # to make it valid JSON. also, the indent of JSON files created by
        # grafana is two, and, by default, indent of to_nice_json is four. to
        # make the original JSON file and the file on the destination
        # _similar_, you need `indent = 2`. you need `ensure_ascii = False` as
        # to_nice_json converts all strings in the input into ASCII by
        # default.
        content: "{{ lookup('file', 'example.json') | from_json | to_nice_json(indent = 2, ensure_ascii = False) }}"
        state: present
    grafana_provisioning_copy_files:
      - dest: "{{ grafana_provisioning_dir }}/dashboards/"
        src: copy
        state: present

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

    # _____________________________________________apt
    apt_repo_keys_to_add:
      - https://packages.grafana.com/gpg.key
      - https://repos.influxdata.com/influxdb.key
    apt_repo_enable_apt_transport_https: yes
    redhat_repo:
      grafana:
        baseurl: https://packages.grafana.com/oss/rpm
        gpgkey: https://packages.grafana.com/gpg.key
        gpgcheck: yes
        enabled: yes
    apt_repo_to_add:
      - "deb https://repos.influxdata.com/debian {% if ansible_distribution == 'Devuan' %}{{ apt_repo_codename_devuan_to_debian[ansible_distribution_release] }}{% else %}{{ ansible_distribution_release }}{% endif %} stable"
      - "deb https://packages.grafana.com/oss/deb stable main"

    # _____________________________________________influxdb
    influxdb_admin_username: admin
    influxdb_admin_password: password
    influxdb_bind_address: 127.0.0.1:8086
    influxdb_databases:
      - database_name: mydatabase
        state: present
    influxdb_users:
      - user_name: read
        user_password: read
        grants:
          - database: mydatabase
            privilege: READ
      - user_name: write
        user_password: write
        grants:
          - database: mydatabase
            privilege: WRITE
    influxdb_sysvinit_default: |
      STDOUT={{ influxdb_log_dir }}/influxd.log
    influxdb_config: |
      reporting-disabled = true
      # this one is bind address for backup process
      bind-address = "127.0.0.1:8088"
      [meta]
        dir = "{{ influxdb_db_dir }}/meta"
      [data]
        dir = "{{ influxdb_db_dir }}/data"
        wal-dir = "{{ influxdb_db_dir }}/wal"
      [coordinator]
      [retention]
      [shard-precreation]
      [monitor]
      [http]
        auth-enabled = true
        bind-address = "{{ influxdb_bind_address }}"
        https-enabled = false
        access-log-path = "{{ influxdb_log_dir }}/access.log"
      [ifql]
      [logging]
      [subscriber]
      [[graphite]]
      [[collectd]]
      [[opentsdb]]
      [[udp]]
      [tls]
    # _____________________________________________telegraf
    os_telegraf_packages:
      FreeBSD:
        - net-mgmt/net-snmp
      OpenBSD:
        - net-snmp
      Debian:
        - snmp
    telegraf_extra_packages: "{{ os_telegraf_packages[ansible_os_family] }}"
    telegraf_config: |
      [global_tags]
      os_family = "{{ ansible_os_family }}"
      [agent]
        interval = "10s"
        round_interval = true
        metric_batch_size = 1000
        metric_buffer_limit = 10000
        collection_jitter = "0s"
        flush_interval = "10s"
        flush_jitter = "0s"
        precision = ""
        debug = false
        quiet = false
        {% if ansible_os_family != "FreeBSD" %}
        logfile = "{{ telegraf_log_dir }}/telegraf.log"
        {% endif %}
        hostname = "{{ ansible_hostname }}"
        omit_hostname = false
      {% if ansible_os_family != "OpenBSD" %}
      [[inputs.cpu]]
        percpu = true
        totalcpu = true
        collect_cpu_time = false
        report_active = false
      {% endif %}
      [[inputs.disk]]
        ignore_fs = ["tmpfs", "devtmpfs", "devfs", "overlay", "aufs", "squashfs"]
      [[inputs.diskio]]
      {% if ansible_os_family != "OpenBSD" %}
      [[inputs.kernel]]
      {% endif %}
      [[inputs.mem]]
      [[inputs.processes]]
      [[inputs.socket_listener]]
        service_address = "tcp://127.0.0.1:8094"
        data_format = "influx"

      [[inputs.swap]]
      # does not work on OpenBSD
      [[inputs.system]]
      [[outputs.influxdb]]
        urls = ["http://{{ influxdb_bind_address }}"]
        database = "mydatabase"
        username = "write"
        password = "write"
        skip_database_creation = true
      [[inputs.netstat]]
      [[inputs.net]]
      [[inputs.temp]]
    # _____________________________________________nginx
    os_project_www_root_dir:
      OpenBSD: /var/www/htdocs
      FreeBSD: /usr/local/www/nginx
      Debian: /var/www/html
      RedHat: /usr/share/nginx/html
    project_www_root_dir: "{{ os_project_www_root_dir[ansible_os_family] }}"

    nginx_config: |
      user {{ nginx_user }};
      worker_processes 1;
      error_log {{ nginx_error_log_file }};
      events {
        worker_connections 1024;
      }
      http {
        include {{ nginx_conf_dir }}/mime.types;
        access_log {{ nginx_access_log_file }};
        default_type application/octet-stream;
        sendfile on;
        keepalive_timeout 65;
        gzip on;
        gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript text/x-js;

        upstream influxdb {
          server {{ influxdb_bind_address }};
          keepalive 10;
        }

        upstream grafana {
          server localhost:3000;
          keepalive 10;
        }

        server {
          listen *:80;
          server_name localhost;
          root {{ project_www_root_dir }};
          location / {
            proxy_pass http://grafana/;
            proxy_redirect default;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_connect_timeout 5;
            proxy_send_timeout 10;
            proxy_read_timeout 20;
          }
          error_page 500 502 503 504 /50x.html;
          location = /50x.html {
          }
        }
      }
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
