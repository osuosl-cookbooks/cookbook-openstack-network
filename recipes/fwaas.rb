# Encoding: utf-8
#
# Cookbook:: openstack-network
# Recipe:: fwaas
#
# Copyright:: 2020, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'openstack-network'

# Make Openstack object available in Chef::Recipe
class ::Chef::Recipe
  include ::Openstack
end

platform_options = node['openstack']['network']['platform']

platform_options['neutron_fwaas_packages'].each do |pkg|
  package pkg do
    options platform_options['package_overrides']
    action :upgrade
  end
end

node.default['openstack']['network_fwaas']['conf'].tap do |conf|
  conf['fwaas']['enabled'] = 'True'
end

node.default['openstack']['network_l3']['conf'].tap do |conf|
  conf['AGENT']['extensions'] = 'fwaas_v2'
end

# As the fwaas package will be installed anyway, configure its config-file attributes following environment.
service_conf = merge_config_options 'network_fwaas'
template node['openstack']['network_fwaas']['config_file'] do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['network']['platform']['user']
  group node['openstack']['network']['platform']['group']
  mode '640'
  variables(
    service_config: service_conf
  )
end
