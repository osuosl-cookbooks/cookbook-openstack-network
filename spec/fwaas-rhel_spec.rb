# Encoding: utf-8
require_relative 'spec_helper'

describe 'openstack-network::fwaas' do
  describe 'centos' do
    let(:runner) { ChefSpec::SoloRunner.new(REDHAT_OPTS) }
    let(:node) { runner.node }
    cached(:chef_run) do
      runner.converge(described_recipe)
    end

    include_context 'neutron-stubs'

    it do
      %w(
        openstack-neutron-fwaas
      ).each do |pkg|
        expect(chef_run).to upgrade_package(pkg)
      end
    end
  end
end
