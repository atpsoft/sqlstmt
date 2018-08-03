require 'simplecov'
SimpleCov.command_name 'Unit Tests'
SimpleCov.add_filter "/test/"
SimpleCov.start

require 'minitest/autorun'
require 'sqlstmt'
