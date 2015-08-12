include websphere_deployer
websphere_deployer::deploy_ear { "http://nexus.dev.rms.nsw.gov.au/content/groups/rms-repo/nswrta/opr/opr-ear/4.2.0/opr-ear-4.2.0.ear":
  deployment_instance => "opr",
}
