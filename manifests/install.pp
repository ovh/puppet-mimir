# == Class: mimir::install
#
# Install Mimir metrics platform.
class mimir::install {
  $log_dir_path      = $::mimir::log_dir_path
  $log_dir_mode      = $::mimir::log_dir_mode
  $log_group         = $::mimir::log_group
  $log_owner         = $::mimir::log_owner
  $log_to_file       = $::mimir::log_to_file
  $manage_user       = $::mimir::manage_user
  $package_ensure    = $::mimir::package_ensure
  $user_extra_groups = $::mimir::user_extra_groups
  $user_home         = $::mimir::user_home
  $user_shell        = $::mimir::user_shell

  package { 'mimir':
    ensure => $package_ensure,
  }

  if $manage_user {
    user { 'mimir':
      ensure     => 'present',
      system     => true,
      groups     => $user_extra_groups,
      shell      => $user_shell,
      home       => $user_home,
      managehome => true,
    }
  }

  if $log_to_file {
    # Create dir for mimir logs
    file { $log_dir_path:
      ensure => 'directory',
      owner  => $log_owner,
      group  => $log_group,
      mode   => $log_dir_mode,
    }
  }
}
