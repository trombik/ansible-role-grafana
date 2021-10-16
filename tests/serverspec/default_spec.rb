require "spec_helper"
require "serverspec"
require "grafana"

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
extra_packages = case os[:family]
                 when "freebsd"
                   %w[net-snmp lsof]
                 when "openbsd"
                   %w[net-snmp]
                 when "debian"
                   %w[snmp lsof]
                 when "redhat"
                   %w[snmp lsof]
                 end
plugins = %w[raintank-worldping-app]
plugins_absent = %w[grafana-clock-panel]
provisioning_files = [
  { name: "datasources/influxdb.yml", regex: /datasources:\n-\s+access: proxy/ },
  { name: "datasources/influxdb.yml", regex: /Managed by ansible/ },
  { name: "dashboards/default.yml", regex: /Managed by ansible/ },
  { name: "dashboards/default.yml", regex: /name: a unique provider name/ },
  { name: "dashboards/json/example.json", regex: /"uid":\s+"LCKDHqDnz"/ }
]
provisioning_copy_files = [
  { name: "dashboards/copy/Linux/linux.json", regex: /"uid":\s+/ }
]
api_port = case os[:family]
           when "freebsd"
             8000
           when "openbsd"
             8001
           when "ubuntu"
             8002
           when "redhat"
             8003
           end

case os[:family]
when "freebsd"
  service = "grafana"
  package = "www/grafana8"
  config_dir = "/usr/local/etc/grafana"
  db_dir = "/var/db/grafana"
  default_group = "wheel"
when "openbsd"
  service = "grafana"
  package = "grafana"
  db_dir = "/var/grafana"
  default_group = "wheel"
  user = "_grafana"
  group = user
end
config = case os[:family]
         when "openbsd"
           "#{config_dir}/config.ini"
         else
           "#{config_dir}/grafana.ini"
         end
provisioning_dir = "#{config_dir}/provisioning"
plugins_dir = "#{db_dir}/plugins"
api_host = "localhost"
api_user = "admin"
api_password = "password"

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
  # directory
  describe file(File.dirname("#{provisioning_dir}/#{f[:name]}")) do
    it { should exist }
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by user }
    it { should be_grouped_into group }
  end

  # file
  describe file("#{provisioning_dir}/#{f[:name]}") do
    it { should exist }
    it { should be_file }
    it { should be_owned_by default_user }
    it { should be_grouped_into group }
    it { should be_mode 640 }
    its(:content) { should match(f[:regex]) }
  end
end

provisioning_copy_files.each do |f|
  describe file("#{provisioning_dir}/#{f[:name]}") do
    it { should exist }
    it { should be_file }
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
  # XXX do not test permission. we do not change the permission in the role.
  # different platforms use different permission, and they changes one day.
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
    it { should be_grouped_into os[:family] =~ /bsd/ ? group : default_group }
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

describe "API" do
  before do
    config = {
      grafana: {
        host: api_host,
        port: api_port
      }
    }
    @g = Grafana::Client.new(config)
    @g.login(username: api_user, password: api_password)
  end

  it "returns dashboard `FreeBSD` in `Test folder`" do
    search = { query: "FreeBSD" }
    res = @g.search_dashboards(search)
    status  = res.dig("status")
    # {"message"=>[{"folderId"=>2, "folderTitle"=>"Test folder", "folderUid"=>"ielL5kOnz", "folderUrl"=>"/d...>"dash-db", "uid"=>"LCKDHqDnz", "uri"=>"db/freebsd", "url"=>"/d/LCKDHqDnz/freebsd"}], "status"=>200}
    message = res.dig("message")
    folder_title = message.first.dig("folderTitle")

    expect(status).to be == 200
    expect(folder_title).to eq "Test folder"
  end

  it "returns dashboard `System` in `Linux`" do
    search = { query: "System" }
    res = @g.search_dashboards(search)
    status  = res.dig("status")
    message = res.dig("message")
    folder_title = message.first.dig("folderTitle")

    expect(status).to be == 200
    expect(folder_title).to eq "Linux"
  end
end
