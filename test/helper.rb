require 'simplecov'
SimpleCov.command_name 'Unit Tests'
SimpleCov.start

require 'coveralls'
Coveralls.wear!

require 'minitest/autorun'
require 'sqlstmt'
