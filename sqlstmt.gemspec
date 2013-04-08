require 'rake'

Gem::Specification.new do |s|
  s.name = 'sqlstmt'
  s.version = '0.1.6'
  s.summary = 'helper for building SQL statements'
  s.description = 'mysql centric (for now) object helpers for building SQL statements'
  s.require_path = 'lib'
  s.required_ruby_version = '>= 1.9.2'
  s.add_runtime_dependency 'dohutil', '>= 0.1.7'
  s.add_development_dependency 'dohtest', '>= 0.1.7'
  s.authors = ['Makani Mason', 'Kem Mason']
  s.bindir = 'bin'
  s.homepage = 'https://github.com/atpsoft/sqlstmt'
  s.license = 'MIT'
  s.email = ['devinfo@atpsoft.com']
  s.extra_rdoc_files = ['MIT-LICENSE']
  s.test_files = FileList["{test}/**/*.rb"].to_a
  s.files = FileList["{lib,test}/**/*"].to_a
end
