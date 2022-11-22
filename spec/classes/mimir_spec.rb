# frozen_string_literal: true

require 'spec_helper'

describe 'mimir' do
  # Run through supported operating systems
  on_supported_os.each do |os, os_facts|
    params_sets = {
      'defaults' => {
        'config_hash'          => nil,
        'package_ensure'       => 'present',
        'manage_user'          => false,
        'user_home'            => '/var/lib/mimir',
        'user_shell'           => '/sbin/nologin',
        'user_extra_groups'    => [],
        'config_owner'         => 'mimir',
        'config_group'         => 'mimir',
        'config_dir'           => '/etc/mimir',
        'custom_args'          => [],
        'systemd_overrides'    => nil,
        'log_to_file'          => false,
        'restart_cmd'          => '/bin/systemctl reload mimir',
        'restart_on_change'    => false,
        'validate_cmd'         => '/usr/local/bin/mimir --modules=true',
      },
      'not_defaults' => {
        'config_hash' => {
          'test' => 'test'
        },
        'package_ensure'        => 'latest',
        'manage_user'           => true,
        'user_home'             => '/test/home',
        'user_shell'            => '/test/bin/shell',
        'user_extra_groups'     => [ 'extra_test_group' ],
        'config_owner'          => 'test_owner',
        'config_group'          => 'test_group',
        'config_dir'            => '/test/config',
        'custom_args'           => [ 'test_arg' ],
        'systemd_overrides'     => {
          'Service' => {
            'LimitNOFILE'       => '42',
            'AdditionalTestKey' => 'test'
          }
        },
        'log_dir_path'          => '/test/log',
        'log_dir_mode'          => '0750',
        'log_file_path'         => 'mimir-test.log',
        'log_file_mode'         => '0640',
        'log_group'             => 'test_group',
        'log_owner'             => 'test_owner',
        'log_to_file'           => true,
        'restart_cmd'           => '/test/bin/restart',
        'restart_on_change'     => true,
        'validate_cmd'          => '/test/bin/validate',
      }
    }
    # Run through parameters sets
    params_sets.each do |params_name, params|
      context "on #{os} with parameters #{params_name}" do
        let(:title) { 'mimir' }
        let(:facts) { os_facts }

        let(:params) { params } if params_name != 'defaults'

        # Test init
        it { is_expected.to compile }
        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('mimir::install') }
        it { is_expected.to contain_class('mimir::config') }
        it { is_expected.to contain_class('mimir::service') }

        # Test install
        it {
          is_expected.to contain_package('mimir')
            .only_with(
              ensure: params['package_ensure'],
            )
        }

        if params['manage_user']
          it {
            is_expected.to contain_user('mimir')
              .only_with(
                ensure: 'present',
                system: true,
                groups: params['user_extra_groups'],
                shell: params['user_shell'],
                home: params['user_home'],
                managehome: true,
              )
          }
        else
          it { is_expected.not_to contain_user('mimir') }
        end

        if params['log_to_file']
          it {
            is_expected.to contain_file(params['log_dir_path'])
              .only_with(
                ensure: 'directory',
                owner: params['log_owner'],
                group: params['log_group'],
                mode: params['log_dir_mode'],
              )
          }
        end

        # Test configuration
        it {
          is_expected.to contain_file(params['config_dir'])
            .only_with(
              ensure: 'directory',
              owner: params['config_owner'],
              group: params['config_group'],
              mode: '0750',
            )
        }

        it {
          is_expected.to contain_file("#{params['config_dir']}/config.yml")
            .only_with(
              ensure: 'file',
              content: params['config_hash'].nil? ? "--- {}\n" : "---\ntest: test\n",
              owner: params['config_owner'],
              group: params['config_group'],
              mode: '0640',
              validate_cmd: params['validate_cmd'],
            )
        }

        it {
          is_expected.to contain_file('/etc/default/mimir')
            .with(
              ensure: 'file',
              owner: 'root',
              group: 'root',
              mode: '0640',
            )
        }

        it {
          is_expected.to contain_systemd__dropin_file('mimir-dropin.conf')
            .with(
              unit: 'mimir.service',
              content:
                if params['systemd_overrides'].nil?
                  "# MANAGED BY PUPPET\n"\
                  "[Service]\n"\
                  "LimitNOFILE=1048576\n"
                else
                  "# MANAGED BY PUPPET\n"\
                  "[Service]\n"\
                  "LimitNOFILE=42\n"\
                  "AdditionalTestKey=test\n"\
                  "StandardOutput=append:#{params['log_dir_path']}/#{params['log_file_path']}\n"\
                  "StandardError=inherit\n"
                end,
            )
        }

        if params['log_to_file']
          it {
            is_expected.to contain_file("#{params['log_dir_path']}/#{params['log_file_path']}")
              .only_with(
                ensure: 'present',
                owner: params['log_owner'],
                group: params['log_group'],
                mode: params['log_file_mode'],
              )
          }

          it {
            is_expected.to contain_logrotate__rule('mimir')
              .with(
                compress: true,
                copytruncate: true,
                create_mode: params['log_file_mode'],
                create_owner: params['log_owner'],
                create_group: params['log_group'],
                ifempty: false,
                missingok: true,
                delaycompress: false,
                path: "#{params['log_dir_path']}/#{params['log_file_path']}",
                rotate: 7,
                rotate_every: 'daily',
              )
          }
        end

        # Test service
        it {
          is_expected.to contain_service('mimir')
            .only_with(
              ensure: 'running',
              enable: 'true',
              hasstatus: 'true',
              hasrestart: 'true',
              restart: params['restart_cmd'],
            )
        }
      end
    end

    # Test errors
    context "on #{os} with parameters colision between log_to_file & StandardOutput" do
      let(:title) { 'mimir' }
      let(:facts) { os_facts }
      let(:params) do
        {
          log_to_file: true,
          systemd_overrides: {
            Service: {
              StandardOutput: 'test'
            }
          }
        }
      end

      it { is_expected.to compile.and_raise_error(%r{log_to_file option is not compatible with systemd overrides: StandardOutput or StandardError}) }
    end

    context "on #{os} with parameters colision between log_to_file & StandardError" do
      let(:title) { 'mimir' }
      let(:facts) { os_facts }
      let(:params) do
        {
          log_to_file: true,
          systemd_overrides: {
            Service: {
              StandardError: 'test'
            }
          }
        }
      end

      it { is_expected.to compile.and_raise_error(%r{log_to_file option is not compatible with systemd overrides: StandardOutput or StandardError}) }
    end
  end
end
