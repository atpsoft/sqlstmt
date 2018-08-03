require 'rake'

Gem::Specification.new do |s|
  s.name = 'sqlstmt'
  s.version = '0.2.10'
  s.summary = 'build SQL statements using method calls instead of strings'
  s.description = 'Build SQL statements using method calls instead of strings. This is not an ORM. It has only been used and tested with MySQL so far but the intention is to make it SQL agnostic.'
  s.required_ruby_version = '>= 2.2.0'
  s.authors = ['Makani Mason', 'Kem Mason']
  s.bindir = 'bin'
  s.homepage = 'https://github.com/atpsoft/sqlstmt'
  s.license = 'MIT'
  s.email = ['devinfo@atpsoft.com']
  s.extra_rdoc_files = ['MIT-LICENSE']
  s.test_files = FileList["{test}/**/*.rb"].to_a
  s.files = FileList["{lib,test}/**/*"].to_a
end
