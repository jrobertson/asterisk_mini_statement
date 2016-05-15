Gem::Specification.new do |s|
  s.name = 'asterisk_mini_statement'
  s.version = '0.1.2'
  s.summary = 'Project under development to output a mini statement of recent 
  telephone calls from the Asterisk Call Detail Records (cdr-csv/Master.csv) file.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/asterisk_mini_statement.rb']
  s.add_runtime_dependency('subunit', '~> 0.2', '>=0.2.4')
  s.add_runtime_dependency('polyrex', '~> 1.1', '>=1.1.1')  
  s.signing_key = '../privatekeys/asterisk_mini_statement.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/asterisk_mini_statement'
end
