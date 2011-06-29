spec = Gem::Specification.new do |s|
  s.name = 'namecoin_client'
  s.summary = 'Client for communicating with namecoind'
  s.author = 'Michael Fellinger <mf@rubyists.com>'
  s.version = '1.0.0'
  s.files = ["lib/namecoin_client.rb"]
  s.add_dependency "json"
  s.add_dependency "addressable"
end
