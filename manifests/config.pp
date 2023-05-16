# == Class: mimir::config
#
# Configure Mimir metrics platform.
# For a deep dive in mimir configuration see https://grafana.com/docs/mimir/latest/
class mimir::config {
  $config_dir        = $::mimir::config_dir
  $config_group      = $::mimir::config_group
  $config_owner      = $::mimir::config_owner
  $custom_args       = $::mimir::custom_args
  $log_dir_path      = $::mimir::log_dir_path
  $log_file_path     = $::mimir::log_file_path
  $log_file_mode     = $::mimir::log_file_mode
  $log_group         = $::mimir::log_group
  $log_level         = $::mimir::log_level
  $log_owner         = $::mimir::log_owner
  $log_to_file       = $::mimir::log_to_file
  $systemd_overrides = $::mimir::systemd_overrides
  $validate_cmd      = $::mimir::validate_cmd



  # Here we ensure that the configuration directory created
  # by the package has the expected owner, group and mode.
  file { $config_dir:
    ensure => 'directory',
    owner  => $config_owner,
    group  => $config_group,
    mode   => '0750'
  }

  # Write mimir configuration file.
  # /!\ Do not remove default mimir configuration file single-process-config.yaml /!\
  # as it is expected by package when upgrading.
  file { "${config_dir}/config.yml":
    ensure       => 'file',
    content      => to_yaml($::mimir::config_hash),
    owner        => $config_owner,
    group        => $config_group,
    mode         => '0640',
    validate_cmd => $validate_cmd
  }

  # The default service file of mimir use an EnvironmentFile where the
  # configuration file to use is define. As per systemd behavior variables
  # defined in Environment are override per the ones from EnvironmentFile.
  # This means we cannot define the CONFIG_FILE environment with a drop-in

  case $::osfamily {
    'debian': {
      $environment_file =  '/etc/default/mimir'
    }
    'redhat':{
      $environment_file =  '/etc/sysconfig/mimir'
    }
    default: {
      $environment_file =  '/etc/default/mimir'
    }

  }

  file { $environment_file:
    ensure  => 'file',
    content => epp('mimir/systemd-default.epp', {'config_dir' => $config_dir, 'custom_args' => $custom_args, 'log_level' => $log_level}),
    owner   => 'root',
    group   => 'root',
    mode    => '0640'
  }

  if $log_to_file {
    if has_key($systemd_overrides, 'Service') and ( has_key($systemd_overrides['Service'], 'StandardOutput') or has_key($systemd_overrides['Service'], 'StandardError')) {
      fail('log_to_file option is not compatible with systemd overrides: StandardOutput or StandardError')
    }
    else {
      $final_systemd_overrides = merge(
        $systemd_overrides,
        {
          'Service' => merge(
            $systemd_overrides['Service'],
            {
              'StandardOutput' => "append:${$log_dir_path}/${log_file_path}",
              'StandardError'  => 'inherit'
            }
          )
        }
      )
    }
  } else {
    $final_systemd_overrides = $systemd_overrides
  }

  # Overriding systemd service parameters
  # using dropin built-in. We will reuse the systemd unit delivered
  # by mimir package
  systemd::dropin_file { 'mimir-dropin.conf':
    unit    => 'mimir.service',
    content => epp('mimir/mimir-dropin.conf.epp', {
        'systemd_overrides' => $final_systemd_overrides
      }
    )
  }

  if $log_to_file {
    # Create log file to be sure it get's the asked permissions
    file { "${log_dir_path}/${log_file_path}":
      ensure => 'present',
      owner  => $log_owner,
      group  => $log_group,
      mode   => $log_file_mode,
    }

    # Define logrotate policy for mimir log file.
    logrotate::rule { 'mimir':
      compress      => true,
      copytruncate  => true,
      create        => true,
      create_mode   => $log_file_mode,
      create_owner  => $log_owner,
      create_group  => $log_group,
      ifempty       => false,
      missingok     => true,
      delaycompress => false,
      path          => "${log_dir_path}/${log_file_path}",
      rotate        => 7,
      rotate_every  => 'daily'
    }
  }
}
