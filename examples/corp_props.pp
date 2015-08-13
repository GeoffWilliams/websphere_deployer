include websphere_deployer
$props_hash = {
  "aaaaaa.webgway.jmsConnectionFactory.brokerURL" => "tcp://localhost:61616",
  "aaaaaa.webgway.sftg.agency.codes"              => "3000,3001",
  "aaaaaa.webgway.batch.schedule.date.format"     => "yyMMddHHmm"
}

websphere_deployer::corp_props { "/tmp/test.properties":
  props_hash => $props_hash,
}
