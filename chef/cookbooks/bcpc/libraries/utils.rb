# Cookbook:: bcpc
# Library:: utils
#
# Copyright:: 2024 Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

return Chef::Log.warn('requires chef-server') if Chef::Config[:solo]

require 'ipaddr'
require 'ipaddress'

def init_cloud?
  nodes = search(:node, 'roles:headnode')
  nodes = nodes.reject { |n| n['hostname'] == node['hostname'] }
  nodes.empty?
end

def init_etcd?
  nodes = search(:node, 'roles:etcdnode')
  nodes = nodes.reject { |n| n['hostname'] == node['hostname'] }
  nodes.empty?
end

def init_rmq?
  nodes = search(:node, 'roles:rmqnode')
  nodes = nodes.reject { |n| n['hostname'] == node['hostname'] }
  nodes.empty?
end

def init_storage?
  nodes = search(:node, 'roles:storageheadnode')
  nodes = nodes.reject { |n| n['hostname'] == node['hostname'] }
  nodes.empty?
end

def bootstrap?
  search(:node, "role:bootstrap AND hostname:#{node['hostname']}").any?
end

def etcdnode?
  search(:node, "role:etcdnode AND hostname:#{node['hostname']}").any?
end

def headnode?
  search(:node, "role:headnode AND hostname:#{node['hostname']}").any?
end

def rmqnode?
  search(:node, "role:rmqnode AND hostname:#{node['hostname']}").any?
end

def storagenode?
  search(:node, "role:storagenode AND hostname:#{node['hostname']}").any?
end

def storageheadnode?
  search(:node, "role:storageheadnode AND hostname:#{node['hostname']}").any?
end

def stubnode?
  search(:node, "role:stubnode AND hostname:#{node['hostname']}").any?
end

def worknode?
  search(:node, "role:worknode AND hostname:#{node['hostname']}").any?
end

def bootstraps
  nodes = search(:node, 'role:bootstrap')
  nodes.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def etcdnodes(exclude: nil, all: false)
  nodes = []

  if !exclude.nil?
    nodes = search(:node, 'roles:etcdnode')
    nodes = nodes.reject { |h| h['hostname'] == exclude }
  elsif all == true
    nodes = search(:node, 'role:etcdnode')
  else
    nodes = search(:node, 'roles:etcdnode')
  end

  nodes.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def headnodes(exclude: nil, all: false)
  nodes = []

  if !exclude.nil?
    nodes = search(:node, 'roles:headnode')
    nodes = nodes.reject { |h| h['hostname'] == exclude }
  elsif all == true
    nodes = search(:node, 'role:headnode')
  else
    nodes = search(:node, 'roles:headnode')
  end

  nodes.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def rmqnodes(exclude: nil, all: false)
  nodes = []

  if !exclude.nil?
    nodes = search(:node, 'roles:rmqnode')
    nodes = nodes.reject { |h| h['hostname'] == exclude }
  elsif all == true
    nodes = search(:node, 'role:rmqnode')
  else
    nodes = search(:node, 'roles:rmqnode')
  end

  nodes.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def storageheadnodes(all: false)
  nodes = if all
            search(:node, 'role:storageheadnode')
          else
            search(:node, 'roles:storageheadnode')
          end

  nodes.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def worknodes(all: false)
  nodes = if all
            search(:node, 'role:worknode')
          else
            search(:node, 'roles:worknode')
          end

  nodes.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def all_nodes
  nodes = search(:node, '*:*')
  nodes.sort! { |a, b| a['hostname'] <=> b['hostname'] }
end

def node_roles
  matches = search(:node, "hostname:#{node['hostname']}")
  raise "the node '#{node['hostname']}' does not exist or has "\
    'multiple matches' if matches.length != 1
  matches[0]['roles']
end

def node_licenses
  matches = search(:node, "hostname:#{node['hostname']}")
  raise "the node '#{node['hostname']}' does not exist or has "\
    'multiple matches' if matches.length != 1
  matches[0]['licenses'].nil? ? [] : matches[0]['licenses']
end

def generate_service_catalog_uri(svcprops, access_level)
  fqdn = node['bcpc']['cloud']['fqdn']
  port = svcprops['ports'][access_level]
  path = svcprops['uris'][access_level]
  "https://#{fqdn}:#{port}/#{path}"
end

def mysqladmin
  region = node['bcpc']['cloud']['region']
  config = data_bag_item(region, 'config')
  {
    'username' => 'root',
    'password' => config['mysql']['users']['root']['password'],
  }
end

def psqladmin
  region = node['bcpc']['cloud']['region']
  config = data_bag_item(region, 'config')
  {
    'username' => config['proxysql']['creds']['admin']['username'],
    'password' => config['proxysql']['creds']['admin']['password'],
  }
end

def db_conn
  if node['bcpc']['proxysql']['enabled']
    {
      'host' => node['bcpc']['proxysql']['host'],
      'port' => node['bcpc']['proxysql']['port'],
    }
  else
    {
      'host' => node['bcpc']['mysql']['host'],
      'port' => node['bcpc']['mysql']['port'],
    }
  end
end

def os_adminrc
  region = node['bcpc']['cloud']['region']
  config = data_bag_item(region, 'config')

  identity = node['bcpc']['catalog']['identity']

  {
    'OS_PROJECT_DOMAIN_ID' => 'default',
    'OS_USER_DOMAIN_ID' => 'default',
    'OS_PROJECT_NAME' => node['bcpc']['openstack']['admin']['project'],
    'OS_USERNAME' => node['bcpc']['openstack']['admin']['username'],
    'OS_PASSWORD' => config['openstack']['admin']['password'],
    'OS_AUTH_URL' => generate_service_catalog_uri(identity, 'admin'),
    'OS_REGION_NAME' => region,
    'OS_IDENTITY_API_VERSION' => '3',
    'OS_VOLUME_API_VERSION' => '3',
  }
end

def etcdctl_env
  if etcdnode?
    {
      'ETCDCTL_API' => '3',
      'ETCDCTL_CACERT' => node['bcpc']['etcd']['ca']['crt']['filepath'],
      'ETCDCTL_CERT' => node['bcpc']['etcd']['server']['crt']['filepath'],
      'ETCDCTL_KEY' => node['bcpc']['etcd']['server']['key']['filepath'],
    }
  elsif headnode?
    {
      'ETCDCTL_API' => '3',
      'ETCDCTL_CACERT' => node['bcpc']['etcd']['ca']['crt']['filepath'],
      'ETCDCTL_CERT' => node['bcpc']['etcd']['client-rw']['crt']['filepath'],
      'ETCDCTL_KEY' => node['bcpc']['etcd']['client-rw']['key']['filepath'],
    }
  else
    {
      'ETCDCTL_API' => '3',
      'ETCDCTL_CACERT' => node['bcpc']['etcd']['ca']['crt']['filepath'],
      'ETCDCTL_CERT' => node['bcpc']['etcd']['client-ro']['crt']['filepath'],
      'ETCDCTL_KEY' => node['bcpc']['etcd']['client-ro']['key']['filepath'],
    }
  end
end

def get_address(cidr)
  IPAddress(cidr).address
end

def ceph_racks
  racks = cloud_racks
  racks.map { |rack| "rack#{rack['id']}" }
end

def local_ceph_rack
  node_map = node_network_map
  "rack#{node_map['rack_id']}"
end

def primary_network_aggregate_cidr
  node['bcpc']['networking']['networks']['primary']['aggregate-cidr']
end

def node_network_map
  # try to get node information via the node hostname
  match = node['hostname'].match(/^.*r(\d+)n(\d+).*$/i)
  # before failing, try matching on the hostname from the metadata API
  if match.nil?
    begin
      client = Net::HTTP.new('169.254.169.254', nil, nil)
      hostname = client.get('/latest/meta-data/hostname').body.split('.')[0]
      match = hostname.match(/^.*r(\d+)n(\d+).*$/i)
    rescue Net::OpenTimeout
    end
    raise 'could not determine node information from hostname' if match.nil?
  end

  {
    'rack_id' => match.captures[0].to_i,
    'node_id' => match.captures[1],
  }
end

def cloud_racks(rack_id: nil)
  racks = node['bcpc']['networking']['racks']

  return racks if rack_id.nil?

  rack = racks.select do |r|
    r['id'] == rack_id
  end

  raise "could not find rack #{rack_id}" if rack.empty?

  rack.first
end

def node_rack
  node_map = node_network_map
  cloud_racks(rack_id: node_map['rack_id'])
end

def node_interfaces(type: nil)
  interfaces = [node_primary_interface]
  return interfaces if type.nil?

  iface = node_interfaces.find { |i| i['type'] == type }
  raise "could not find interface #{type}" if iface.nil?

  iface
end

def cloud_networks(network: nil)
  networks = node['bcpc']['networking']['networks']
  return networks if network.nil?
  raise "#{network} not found" unless networks.key?(network)
  networks[network]
end

def node_primary_interface
  node_interface(
    type: 'primary',
    ip_address: node['service_ip']
  )
end

def node_interface(type: nil, ip_address: nil)
  rack = node_rack
  rack_network = rack['networks'][type]
  cloud_network = cloud_networks(network: type)

  interface = {
    'type' => type,
    'ip' => ip_address,
    'prefix' => IPAddress(rack_network['cidr']).prefix.to_i,
    'gw' => rack_network['gateway'],
    'dev' => cloud_network['interface'],
  }

  interface['vlan'] = cloud_network['vlan'] if cloud_network.key?('vlan')
  interface['mtu'] = cloud_network['mtu'] if cloud_network.key?('mtu')

  interface
end

def generate_ip_address(source_ip:, network_cidr:)
  # generate ip address by using the source ip and applying
  # the same ip host id to the desired network cidr
  prefix = IPAddress(network_cidr).prefix.to_i
  host_id = (IPAddr.new(source_ip) << prefix >> prefix).to_i
  host_network = IPAddr.new(network_cidr)
  host_network = host_network >> (32 - prefix) << (32 - prefix)

  (host_network | host_id).to_s
end

# take an IPAddress cidr object and break it up into /24 chunks
def cidr_to_reverse_zones(cidr)
  zones = []

  raise 'cidr prefix cannot be greater than 24' if cidr.prefix > 24

  if cidr.prefix == 8
    return [
      {
        'cidr' => IPAddress(cidr.to_string),
        'zone' => cidr.octets.reverse.drop(3).push('in-addr.arpa').join('.'),
      },
    ]
  end

  if cidr.prefix == 16
    return [
      {
        'cidr' => IPAddress(cidr.to_string),
        'zone' => cidr.octets.reverse.drop(2).push('in-addr.arpa').join('.'),
      },
    ]
  end

  # 24 - the target cidr prefix will give us the amount of network bits we
  # can use for the /24 networks
  network_bits = 24 - cidr.prefix.to_i

  # 2 ^ $network_bits gives us the amount of /24's we can have
  networks = 2**network_bits

  # loop over all possible /24's in the target network cidr and return them
  # as individual zones
  (0..(networks - 1)).each do |i|
    zone = IPAddress(cidr.to_i + (256 * i))
    zones.push(
      'cidr' => IPAddress("#{zone}/24"),
      'zone' => zone.octets.reverse.drop(1).push('in-addr.arpa').join('.')
    )
  end

  zones
end

def openstack_endpoints
  Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
  os_command = 'openstack endpoint list --format json'
  os_command_out = shell_out(os_command, env: os_adminrc)
  endpoint_list = JSON.parse(os_command_out.stdout)

  # build a host of service_type => list of interfaces present
  groups = endpoint_list.group_by { |e| e['Service Type'] }
  groups.map { |k, v| [k, v.map { |e| e['Interface'] }] }.to_h
end

def openstack_services
  Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
  os_command = 'openstack service list --format json'
  os_command_out = shell_out(os_command, env: os_adminrc)
  service_list = JSON.parse(os_command_out.stdout)

  # build a hash of service_type => list of uris
  service_list.map { |s| s['Type'] }
end

# Determine the maximum sane value for a ceph pool's "size".
# If size N is requested but we have fewer than N hosts, then objects will
# remain degraded. This function clips the configured replication factor to
# the number of storagenodes configured in the cluster (or 1, in the case
# that the cluster is still being bootstrapped).
def ceph_pool_size(requested_size)
  # Assume default CRUSH replication policy of host
  num_storagenodes = search(:node, 'roles:storagenode').length
  [[requested_size, num_storagenodes].min, 1].max
end

def etcd_advertised_name(member = node)
  hosts_to_cnames = node['bcpc']['etcd']['host_to_cnames']
  hosts_to_cnames.fetch(member['hostname'], member['service_ip'])
end

def add_qos_to_volume_type(backend)
  Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)

  # create a qos policy
  backend_name = "#{backend['name']}"
  qos_name = "#{backend_name}-qos"
  qos_create_opts = []
  backend['qos'].each do |k, v|
    qos_create_opts.push("--property #{k}=#{v}")
  end

  cmd = 'openstack volume qos create ' \
    "#{qos_create_opts.join(' ')} #{qos_name}"
  cmd_out = shell_out(cmd, env: os_adminrc)
  raise 'unable to create a qos policy' if cmd_out.error?

  # associate the qos policy to the volume type
  cmd = 'openstack volume qos associate ' \
    "#{qos_name} #{backend_name}"
  cmd_out = shell_out(cmd, env: os_adminrc)
  raise 'unable to associate the qos policy' if cmd_out.error?
end

def remove_qos_from_volume_type(backend)
  Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)

  # disassociate the qos policy from the volume type
  backend_name = "#{backend['name']}"
  qos_name = "#{backend_name}-qos"
  cmd = 'openstack volume qos disassociate ' \
    "--volume-type #{backend_name} #{qos_name}"
  cmd_out = shell_out(cmd, env: os_adminrc)
  raise 'unable to disassociate the qos policy' if cmd_out.error?

  # delete the qos policy
  cmd = "openstack volume qos delete #{qos_name}"
  cmd_out = shell_out(cmd, env: os_adminrc)
  raise 'unable to delete the qos policy' if cmd_out.error?
end
