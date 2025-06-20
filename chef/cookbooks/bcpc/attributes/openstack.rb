###############################################################################
# openstack
###############################################################################
if platform?('ubuntu')
  if node['platform_version'] == '20.04'
    default['bcpc']['openstack']['repo']['enabled'] = true
  elsif ['22.04'].include? node['platform_version']
    default['bcpc']['openstack']['repo']['enabled'] = false
  end
end
default['bcpc']['openstack']['repo']['url'] = 'http://ubuntu-cloud.archive.canonical.com/ubuntu'

default['bcpc']['openstack']['repo']['release'] = 'yoga'
default['bcpc']['openstack']['repo']['branch'] = 'updates'
default['bcpc']['openstack']['repo']['key'] = 'openstack/release.key'

default['bcpc']['openstack']['admin']['username'] = 'admin'
default['bcpc']['openstack']['admin']['project'] = 'admin'

default['bcpc']['openstack']['services']['workers'] = 1
default['bcpc']['openstack']['services']['worker_threads'] = 1

###############################################################################
# openstack flavors
###############################################################################

default['bcpc']['openstack']['flavors']['enabled'] = false

default['bcpc']['openstack']['flavors']['generic1.tiny']['vcpus'] = 1
default['bcpc']['openstack']['flavors']['generic1.tiny']['ram'] = 512
default['bcpc']['openstack']['flavors']['generic1.tiny']['disk'] = 1

default['bcpc']['openstack']['flavors']['generic1.small']['vcpus'] = 1
default['bcpc']['openstack']['flavors']['generic1.small']['ram'] = 2048
default['bcpc']['openstack']['flavors']['generic1.small']['disk'] = 20

default['bcpc']['openstack']['flavors']['generic1.medium']['vcpus'] = 2
default['bcpc']['openstack']['flavors']['generic1.medium']['ram'] = 4096
default['bcpc']['openstack']['flavors']['generic1.medium']['disk'] = 40

default['bcpc']['openstack']['flavors']['generic1.large']['vcpus'] = 4
default['bcpc']['openstack']['flavors']['generic1.large']['ram'] = 8192
default['bcpc']['openstack']['flavors']['generic1.large']['disk'] = 40

default['bcpc']['openstack']['flavors']['generic1.xlarge']['vcpus'] = 8
default['bcpc']['openstack']['flavors']['generic1.xlarge']['ram'] = 16384
default['bcpc']['openstack']['flavors']['generic1.xlarge']['disk'] = 40

default['bcpc']['openstack']['flavors']['generic1.2xlarge']['vcpus'] = 16
default['bcpc']['openstack']['flavors']['generic1.2xlarge']['ram'] = 32768
default['bcpc']['openstack']['flavors']['generic1.2xlarge']['disk'] = 40

default['bcpc']['openstack']['flavors']['generic2.small']['vcpus'] = 1
default['bcpc']['openstack']['flavors']['generic2.small']['ram'] = 6144
default['bcpc']['openstack']['flavors']['generic2.small']['disk'] = 50

default['bcpc']['openstack']['flavors']['generic2.medium']['vcpus'] = 2
default['bcpc']['openstack']['flavors']['generic2.medium']['ram'] = 12288
default['bcpc']['openstack']['flavors']['generic2.medium']['disk'] = 100

default['bcpc']['openstack']['flavors']['generic2.large']['vcpus'] = 4
default['bcpc']['openstack']['flavors']['generic2.large']['ram'] = 24576
default['bcpc']['openstack']['flavors']['generic2.large']['disk'] = 100

default['bcpc']['openstack']['flavors']['generic2.xlarge']['vcpus'] = 8
default['bcpc']['openstack']['flavors']['generic2.xlarge']['ram'] = 49152
default['bcpc']['openstack']['flavors']['generic2.xlarge']['disk'] = 100

default['bcpc']['openstack']['flavors']['generic2.2xlarge']['vcpus'] = 16
default['bcpc']['openstack']['flavors']['generic2.2xlarge']['ram'] = 98304
default['bcpc']['openstack']['flavors']['generic2.2xlarge']['disk'] = 100

# oslo.messaging
# A workaround for bug reported:
# https://bugs.launchpad.net/neutron/+bug/1965140/
# Disabling this config for all services as the default
# is changed to false in the upstream fix.
default['bcpc']['openstack']['oslo_messaging_rabbit']['heartbeat_in_pthread'] = false
