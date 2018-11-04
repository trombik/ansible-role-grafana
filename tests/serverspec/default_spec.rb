require "spec_helper"
require "serverspec"

package = "grafana"
service = "grafana"
config_dir = "/etc/grafana"
user    = "grafana"
group   = "grafana"
ports   = [3000]
log_dir = "/var/log/grafana"
db_dir  = "/var/lib/grafana"
default_user = "root"
default_group = "root"
extra_packages = %w[zsh]

case os[:family]
when "freebsd"
  package = "www/grafana5"
  config_dir = "/usr/local/etc"
  db_dir = "/var/db/grafana"
  default_group = "wheel"
end
config = "#{config_dir}/grafana.conf"

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
  it { should be_grouped_into default_group }
  it { should be_mode 644 }
  its(:content) { should match(/^# Managed by ansible$/) }
  its(:content) { should match(/^logs = #{log_dir}$/) }
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
  it { should be_mode 644 }
  its(:content) { should match(/msg="HTTP Server Listen"/) }
end

describe file(db_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

%w[plugins provisioning].each do |d|
  describe file "#{db_dir}/#{d}" do
    it { should exist }
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
  end
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
    its(:content) { should match(/^grafana_conf="#{config}"$/) }
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
