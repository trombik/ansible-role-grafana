require "spec_helper"
require "serverspec"

package = "grafana"
service = "grafana-server"
config_dir = "/etc/grafana"
user    = "grafana"
group   = "grafana"
ports   = [3000]
log_dir = "/var/log/grafana"
db_dir  = "/var/lib/grafana"
default_user = "root"
default_group = "root"
extra_packages = %w[zsh]
plugins = %w[raintank-worldping-app]
plugins_absent = %w[grafana-clock-panel]
provisioning_files = [
  { name: "datasources/influxdb.yml", regex: /datasources:\n-\s+access: proxy/ },
  { name: "datasources/influxdb.yml", regex: /Managed by ansible/ },
  { name: "provisioning/dashboards/default.yml", regex: /Managed by ansible/ },
  { name: "provisioning/dashboards/default.yml", regex: /name: a unique provider name/ },
  { name: "provisioning/dashboards/json/empty.js", regex: /{}/ }
]

case os[:family]
when "freebsd"
  service = "grafana"
  package = "www/grafana6"
  config_dir = "/usr/local/etc"
  db_dir = "/var/db/grafana"
  default_group = "wheel"
end
config = "#{config_dir}/grafana.ini"
provisioning_dir = "#{config_dir}/provisioning"
plugins_dir = "#{db_dir}/plugins"

describe package(package) do
  it { should be_installed }
end

extra_packages.each do |p|
  describe package p do
    it { should be_installed }
  end
end

describe file(config) do
  it { should exist }
  it { should be_file }
  it { should be_owned_by default_user }
  it { should be_grouped_into group }
  it { should be_mode 640 }
  its(:content) { should match(/^# Managed by ansible$/) }
  its(:content) { should match(/^logs = #{log_dir}$/) }
end

provisioning_files.each do |f|
  describe file(File.dirname("#{provisioning_dir}/#{f[:name]}")) do
    it { should exist }
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by default_user }
    it { should be_grouped_into group }
  end

  describe file("#{provisioning_dir}/#{f[:name]}") do
    it { should exist }
    it { should be_file }
    it { should be_owned_by default_user }
    it { should be_grouped_into group }
    it { should be_mode 640 }
    its(:content) { should match(f[:regex]) }
  end
end

describe file "#{provisioning_dir}/datasources/foo.yml" do
  it { should_not exist }
end

describe file(log_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file "#{log_dir}/grafana.log" do
  it { should exist }
  it { should be_file }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it do
    pending "cannot find where the file mode is defined" if os[:family] == "freebsd"
    should be_mode 640
  end
  its(:content) { should match(/msg="HTTP Server Listen"/) }
end

describe file(db_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file plugins_dir do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

plugins.each do |p|
  describe file "#{plugins_dir}/#{p}" do
    it { should exist }
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by default_user }
    it { should be_grouped_into os[:family] == "freebsd" ? group : default_group }
  end
end

plugins_absent.each do |p|
  describe file "#{plugins_dir}/#{p}" do
    it { should_not exist }
  end
end

describe command "grafana-cli --pluginsDir #{plugins_dir} plugins ls" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  plugins.each do |p|
    its(:stdout) { should match(/^#{p}\s+@\s+\d+\.\d+\.\d+\s*$/) }
  end
end

describe file provisioning_dir do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by default_user }
  it { should be_grouped_into group }
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/grafana") do
    it { should be_file }
    it { should exist }
    it { should be_file }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    it { should be_mode 644 }
    its(:content) { should match(/^# Managed by ansible$/) }
    its(:content) { should match(/^grafana_conf=#{config}$/) }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
