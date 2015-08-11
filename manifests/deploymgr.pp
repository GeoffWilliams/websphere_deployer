class websphere_deployer::deploymgr(
    $host         = $::hostname
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

  $script_dir    = "${base_dir}/scripts"
  $script_files  = $websphere_deployer::params::script_files
  $rw_dirs = $websphere_deployer::params::rw_dirs
  $ro_dirs = $websphere_deployer::params::ro_dirs


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
