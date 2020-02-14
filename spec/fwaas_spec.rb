# Encoding: utf-8
require_relative 'spec_helper'

describe 'openstack-network::fwaas' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) do
      node.override['openstack']['network_fwaas']['enabled'] = true
      runner.converge(
        described_recipe,
        'openstack-network::ml2_core_plugin',
        'openstack-network::server',
        'openstack-network::l3_agent'
      )
    end

    include_context 'neutron-stubs'

    it do
      %w(
        python3-neutron-fwaas
      ).each do |pkg|
        expect(chef_run).to upgrade_package(pkg)
      end
    end

    describe '/etc/neutron/fwaas_driver.ini' do
      let(:file) { chef_run.template('/etc/neutron/fwaas_driver.ini') }
      it do
        expect(chef_run).to create_template(file.name).with(
          source: 'openstack-service.conf.erb',
          cookbook: 'openstack-common',
          user: 'neutron',
          group: 'neutron',
          mode: '640'
        )
      end

      [
        /^agent_version = v2$/,
        /^driver = neutron_fwaas.services.firewall.service_drivers.agents.drivers.linux.iptables_fwaas_v2.IptablesFwaasDriver$/,
        /^enabled = True$/,
      ].each do |line|
        it do
          expect(chef_run).to render_config_file(file.name).with_section_content('fwaas', line)
        end
      end
    end
    describe '/etc/neutron/l3_agent.ini' do
      it do
        [
          /^extensions = fwaas_v2$/,
        ].each do |line|
          expect(chef_run).to render_config_file('/etc/neutron/l3_agent.ini').with_section_content('AGENT', line)
        end
      end
    end
    describe '/etc/neutron/neutron.conf' do
      let(:file) { chef_run.template('/etc/neutron/neutron.conf') }
      [
        /^service_plugins = firewall_v2,router$/,
      ].each do |line|
        it do
          expect(chef_run).to render_config_file(file.name).with_section_content('DEFAULT', line)
        end
      end
      [
        /^service_provider = FIREWALL_V2:fwaas_db:neutron_fwaas.services.firewall.service_drivers.agents.agents.FirewallAgentDriver:default$/,
      ].each do |line|
        it do
          expect(chef_run).to render_config_file(file.name).with_section_content('service_providers', line)
        end
      end
    end
  end
end
