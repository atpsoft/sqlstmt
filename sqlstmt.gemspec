require 'rake'

Gem::Specification.new do |s|
  s.name = 'sqlstmt'
  s.version = '0.2.3'
  s.summary = 'build SQL statements in a modular fashion, one piece at a time'
  s.description = 'build SQL statements in a modular fashion, one piece at a time; only used/tested with MySQL so far'
  s.require_path = 'lib'
  s.required_ruby_version = '>= 2.0.0'
  s.authors = ['Makani Mason', 'Kem Mason']
  s.bindir = 'bin'
  s.homepage = 'https://github.com/atpsoft/sqlstmt'
  s.license = 'MIT'
  s.email = ['devinfo@atpsoft.com']
  s.extra_rdoc_files = ['MIT-LICENSE']
  s.test_files = FileList["{test}/**/*.rb"].to_a
  s.files = FileList["{lib,test}/**/*"].to_a
end
