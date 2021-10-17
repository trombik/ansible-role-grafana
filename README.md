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
    - name: trombik.influxdb
    - name: trombik.haproxy
    - name: trombik.telegraf
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
    os_telegraf_extra_packages:
      FreeBSD:
        - net-mgmt/net-snmp
        - lsof
      OpenBSD:
        - net-snmp
      Debian:
        - snmp
        - lsof
      RedHat:
        - snmp
        - lsof
    telegraf_extra_packages: "{{ os_telegraf_extra_packages[ansible_os_family] }}"
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
      {% if ansible_os_family != "OpenBSD" and ansible_os_family != 'FreeBSD' %}
      [[inputs.kernel]]
      # requires /proc/stat
      {% endif %}
      [[inputs.mem]]
      [[inputs.processes]]
      [[inputs.socket_listener]]
        service_address = "tcp://127.0.0.1:8094"
        data_format = "influx"

      [[inputs.swap]]
      [[inputs.system]]
        fielddrop = ["uptime_format"]
      [[outputs.influxdb]]
        urls = ["http://{{ influxdb_bind_address }}"]
        database = "mydatabase"
        username = "write"
        password = "write"
        skip_database_creation = true
      {% if ansible_os_family != 'OpenBSD' %}
      [[inputs.netstat]]
      # requires lsof
      {% endif %}
      [[inputs.net]]
      {% if ansible_os_family != 'FreeBSD' and ansible_os_family != 'OpenBSD' %}
      [[inputs.temp]]
      {% endif %}
      {% if ansible_os_family != 'OpenBSD' %}
      [[inputs.internet_speed]]
      # requires telegraf 1.20.x
        interval = "10m"
        enable_file_download = true
      {% endif %}
      [[inputs.net_response]]
        protocol = "tcp"
        address = "localhost:80"
        fielddrop = ["result_type", "string_found"]
      [[inputs.haproxy]]

    # _____________________________________________haproxy
    project_backend_host: 127.0.0.1
    project_backend_port: 3000
    haproxy_config: |
      global
        daemon
      {% if ansible_os_family == 'FreeBSD' %}
      # FreeBSD package does not provide default
        maxconn 4096
        log /var/run/log local0 notice
          user {{ haproxy_user }}
          group {{ haproxy_group }}
      {% elif ansible_os_family == 'Debian' %}
        log /dev/log  local0
        log /dev/log  local1 notice
        chroot {{ haproxy_chroot_dir }}
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
        stats timeout 30s
        user {{ haproxy_user }}
        group {{ haproxy_group }}

        # Default SSL material locations
        ca-base /etc/ssl/certs
        crt-base /etc/ssl/private

        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
          ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
          ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
          ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
      {% elif ansible_os_family == 'OpenBSD' %}
        log 127.0.0.1   local0 debug
        maxconn 1024
        chroot {{ haproxy_chroot_dir }}
        uid 604
        gid 604
        pidfile /var/run/haproxy.pid
      {% endif %}

      defaults
        log global
        mode http
        timeout connect 5s
        timeout client 10s
        timeout server 10s
        option  httplog
        option  dontlognull
        retries 3
        maxconn 2000
      {% if ansible_os_family == 'Debian' %}
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http
      {% elif ansible_os_family == 'OpenBSD' %}
        option  redispatch
      {% endif %}

      frontend http-in
        bind *:80
        default_backend servers

      # enable stats for grafana
      # The default URI compiled in HAProxy is "/haproxy?stats"
      listen stats
        bind *:1936
        stats enable
        stats refresh 60s

      backend servers
        option forwardfor
        server server1 {{ project_backend_host }}:{{ project_backend_port }} maxconn 32 check

    os_haproxy_flags:
      FreeBSD: |
        haproxy_config="{{ haproxy_conf_file }}"
        #haproxy_flags="-q -f ${haproxy_config} -p ${pidfile}"
      Debian: |
        #CONFIG="/etc/haproxy/haproxy.cfg"
        #EXTRAOPTS="-de -m 16"
      OpenBSD: ""
    haproxy_flags: "{{ os_haproxy_flags[ansible_os_family] }}"
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
