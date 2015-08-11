class websphere_deployer::deploymgr(
    $host         = $::hostname,
    $base_dir     = $websphere_deployer::params::base_dir,
    $cron_ensure  = present,
    $user         = $websphere_deployer::params::user,
    $group        = $websphere_deployer::params::group,
    $deploy_freq  = $websphere_deployer::params::deploy_freq,
    $cron_command = $websphere_deployer::params::cron_command,
) inherits websphere_deployer::params {

  # By default, only root owns files.  This gives some protection against a 
  # hijacked `wsadmin` account (eg though web-->shell injection)
  File {
    owner => "root",
    group => "root",
    mode  => "0644",
  }

  $script_dir    = "${base_dir}/${websphere_deployer::params::script_dir_name}"
  $bin_dir       = "${base_dir}/${websphere_deployer::params::bin_dir_name}"
  $script_files  = $websphere_deployer::params::script_files
  $bin_files     = $websphere_deployer::params::bin_files
  $rw_dirs       = $websphere_deployer::params::rw_dirs
  $ro_dirs       = $websphere_deployer::params::ro_dirs

  file { $base_dir:
    ensure => directory,
  }

  # directories owned by `wsadmin`
  file { $rw_dirs:
    ensure => directory,
    owner  => $user,
    group  => $group,
  }

  # directories that are RO to wsadmin user (security)
  file{ $ro_dirs:
    ensure => directory,
  }

  # Install deployment scrips using the puppet fileserver.  Long-term plan is
  # to replace these with a tarball or RPM file downloaded from corporate repo
  $script_files.each |$script_file| {
    file { "${script_dir}/${script_file}":
      ensure => file,
      source => "puppet:///modules/${module_name}/${script_file}",
      mode   => "0755",
    }
  }

  $bin_files.each |$bin_file| {
    file { "${bin_dir}/${bin_file}":
      ensure => file,
      source => "puppet:///modules/${module_name}/${bin_file}",
      mode   => "0755",
    }
  }

  
  # deployment cronjob - every 5 minutes
  cron { "websphere_deploymgr":
    ensure  => $cron_ensure,
    command => $cron_command,
    user    => $user,
    minute  => $deploy_freq,
  }
}
