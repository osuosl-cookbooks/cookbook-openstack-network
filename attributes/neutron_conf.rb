# attribute can be used in wrapper cookbooks to handover secrets (will not be
# saved after successfull chef run)
default['openstack']['network']['conf_secrets'] = {}

service_provider = node.default['openstack']['network']['service_provider']
if node['openstack']['network_fwaas']['enabled']
  service_provider <<
    'FIREWALL_V2:fwaas_db:neutron_fwaas.services.firewall.service_drivers.agents.agents.FirewallAgentDriver:default'
end
if node['openstack']['network_lbaas']['enabled']
  service_provider <<
    'LOADBALANCERV2:Haproxy:neutron_lbaas.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default'
end

default['openstack']['network']['conf'].tap do |conf|
  # [DEFAULT] section
  if node['openstack']['network']['syslog']['use']
    conf['DEFAULT']['log_config_append'] = '/etc/openstack/logging.conf'
  else
    conf['DEFAULT']['log_dir'] = '/var/log/neutron'
  end
  conf['DEFAULT']['control_exchange'] = 'neutron'
  conf['DEFAULT']['core_plugin'] = 'ml2'
  conf['DEFAULT']['auth_strategy'] = 'keystone'
  conf['DEFAULT']['notify_nova_on_port_status_changes'] = true
  conf['DEFAULT']['notify_nova_on_port_data_changes'] = true
  conf['DEFAULT']['service_plugins'] = 'router'
  if node['openstack']['network_fwaas']['enabled']
    conf['DEFAULT']['service_plugins'] =
      [
        'firewall_v2',
        conf['DEFAULT']['service_plugins'],
      ].flatten.sort.join(',')
    conf['service_providers']['service_provider'] =
      'FIREWALL_V2:fwaas_db:neutron_fwaas.services.firewall.service_drivers.agents.agents.FirewallAgentDriver:default'
  end
  if node['openstack']['network_lbaas']['enabled']
    conf['DEFAULT']['service_plugins'] =
      [
        'neutron_lbaas.services.loadbalancer.plugin.LoadBalancerPluginv2',
        conf['DEFAULT']['service_plugins'],
      ].flatten.sort.join(',')
  end

  # [agent] section
  if node['openstack']['network']['use_rootwrap']
    conf['agent']['root_helper'] = 'sudo neutron-rootwrap /etc/neutron/rootwrap.conf'
  end

  # [keystone_authtoken] section
  conf['keystone_authtoken']['auth_type'] = 'password'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  conf['keystone_authtoken']['username'] = 'neutron'
  conf['keystone_authtoken']['user_domain_name'] = 'Default'
  conf['keystone_authtoken']['project_domain_name'] = 'Default'
  conf['keystone_authtoken']['project_name'] = 'service'
  conf['keystone_authtoken']['auth_version'] = 'v3'
  # [nova] section
  conf['nova']['auth_type'] = 'password'
  conf['nova']['region_name'] = node['openstack']['region']
  conf['nova']['username'] = 'nova'
  conf['nova']['user_domain_name'] = 'Default'
  conf['nova']['project_name'] = 'service'
  conf['nova']['project_domain_name'] = 'Default'

  # [oslo_concurrency] section
  conf['oslo_concurrency']['lock_path'] = '/var/lib/neutron/lock'
end
