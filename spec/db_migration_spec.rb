# Encoding: utf-8
require_relative 'spec_helper'

describe 'openstack-network::db_migration' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) do
      node.override['openstack']['compute']['network']['service_type'] = 'neutron'
      runner.converge(described_recipe)
    end

    it 'uses db upgrade head with default timeout for neutron-server' do
      expect(chef_run).to run_execute('migrate network database').with(
        command: "neutron-db-manage --config-file /etc/neutron/neutron.conf upgrade head\n",
        timeout: 3600
      )
    end

    context 'uses db upgrade head with timeout override for neutron-server' do
      cached(:chef_run) do
        node.override['openstack']['network']['dbsync_timeout'] = 1234
        runner.converge(described_recipe)
      end
      it do
        expect(chef_run).to run_execute('migrate network database').with(
          command: "neutron-db-manage --config-file /etc/neutron/neutron.conf upgrade head\n",
          timeout: 1234
        )
      end
    end
    context 'run db-migration when services are enabled' do
      cached(:chef_run) do
        node.override['openstack']['network_fwaas']['enabled'] = true
        node.override['openstack']['network_lbaas']['enabled'] = true
        node.override['openstack']['network']['core_plugin_config_file'] = '/etc/neutron/plugins/ml2/ml2_conf.ini'
        runner.converge(described_recipe)
      end
      it 'uses db upgrade head when lbaas is enabled' do
        expect(chef_run).to run_execute('migrate lbaas database').with(
          command: "neutron-db-manage --subproject neutron-lbaas --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head\n",
          timeout: 3600
        )
      end
      it 'uses db upgrade head when fwaas is enabled' do
        expect(chef_run).to run_execute('migrate fwaas database').with(
          command: "neutron-db-manage --subproject neutron-fwaas --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head\n",
          timeout: 3600
        )
      end
    end
    context 'run db-migration when services are enabled' do
      cached(:chef_run) do
        node.override['openstack']['network']['core_plugin_config_file'] = '/etc/neutron/plugins/ml2/ml2_conf.ini'
        runner.converge(described_recipe)
      end

      it 'does not use db upgrade head when fwaas is not enabled' do
        expect(chef_run).not_to run_execute('migrate fwaas database')
      end

      it 'does not use db upgrade head when lbaas is not enabled' do
        expect(chef_run).not_to run_execute('migrate lbaas database')
      end
    end
  end
end
