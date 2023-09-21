# == Class: mimir::service
#
# Manage service associated to Mimir metrics platform.
class mimir::service {
  $restart_cmd = $::mimir::restart_cmd

  service { 'mimir':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    restart    => $restart_cmd,
  }
}
