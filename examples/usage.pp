

class { "deploymgr": }


corp_properties { "systest_nswrta": 
  app_server => 
}

deploy_ear { "http://nexus.dev.rms.nsw.gov.au/content/groups/rms-repo/nswrta/opr/opr-ear/4.2.0/opr-ear-4.2.0.ear":
  deployment_instance => "opr",
}
