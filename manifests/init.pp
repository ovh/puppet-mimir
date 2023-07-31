# == Class: mimir
#
# Install, configure, manage Mimir metrics platform.
# For a deep dive in mimir configuration see https://grafana.com/docs/mimir/latest/
#
# @param package_ensure Mimir version under the form X.X.X
# @param manage_user Boolean to specify if module should manage mimir user
# @param user_home Home directory for the managed user
# @param user_shell Binary to use as shell for managed user
# @param user_extra_groups Additionnal groups the managed user should be connected to
# @param config_dir Directory to store the mimir configuration
# @param config_group Group to use for configuration resources
# @param config_hash Hash containing the configuration keys to override
# @param config_owner Owner to use for configuration resources
# @param custom_args Additional arguments to set to the mimir process
# @param log_dir_path Directory to store mimir logs if log to file is enabled
# @param log_dir_mode Mode of the directory used to store logs
# @param log_file_path Filename to store mimir logs if log to file is enabled
# @param log_file_mode Mode of the file used to store logs
# @param log_group Group to use for log resources
# @param log_level Log level to use for process mimir
# @param log_owner Owner to use for log resources
# @param log_to_file Should log be kept in journald or sent to a dedicated file
# @param validate_cmd Command use to validate configuration
# @param restart_cmd Command use to restart/reload process
# @param restart_on_change Should the process be restarted on configuration changes
# @param systemd_overrides List of systemd parameters to override
class mimir (
    ##
    # Installation related parameters
    ##
    String    $package_ensure    = 'present',
    Boolean   $manage_user       = false,
    String    $user_home         = '/var/lib/mimir',
    String    $user_shell        = '/sbin/nologin',
    Array     $user_extra_groups = [],

    ##
    # Configuration related parameters
    ##
    String    $config_dir        = '/etc/mimir',
    String    $config_group      = 'mimir',
    # Be careful, this hash should only contains keys overriding mimir defaults (implicit configuration).
    # Check here to find them: https://grafana.com/docs/mimir/latest/operators-guide/configure/reference-configuration-parameters/
    Hash      $config_hash       = {},
    String    $config_owner      = 'mimir',
    Array     $custom_args       = [],
    String    $log_dir_path      = '/var/log/mimir',
    String    $log_dir_mode      = '0700',
    String    $log_file_path     = 'mimir.log',
    String    $log_file_mode     = '0600',
    String    $log_group         = 'root',
    String    $log_level         = 'info',
    String    $log_owner         = 'root',
    Boolean   $log_to_file       = false,
    # Note: https://github.com/grafana/mimir/issues/2588
    String    $validate_cmd      = '/usr/local/bin/mimir --modules=true -config.file %',

    ##
    # Systemd related parameters
    ##
    # Set default mimir systemd service restart command
    String    $restart_cmd       = '/bin/systemctl reload mimir',
    Boolean   $restart_on_change = true,
    Hash      $systemd_overrides = {
        'Service' => {
            # Mimir needs to open quite a lot of socket, this value seems widely used for high traffic softwares.
            'LimitNOFILE' => '1048576'
        }
    }
) {
    contain ::mimir::install
    contain ::mimir::config
    contain ::mimir::service

    Class['mimir::install'] -> Class['mimir::config'] -> Class['mimir::service']
    if $restart_on_change {
        Class['mimir::config'] ~> Class['mimir::service']
    }
}
