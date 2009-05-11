#!/usr/bin/env ruby

require 'mkmf'

def find_eventmachine
  require 'rubygems'
  gem 'eventmachine'
  paths = []
  Gem.all_load_paths.each { |path|
    path.sub!(/\/lib$/, '/ext')
    paths << path if path.index /eventmachine/
  }
  paths
  # FIXME:
  #['/home/stephan/programming/eventmachine/ext']
end

dir_config("em_asyncns")
find_header("asyncns.h")
find_header("ed.h", find_eventmachine)
$defs.push "-DOS_UNIX"
find_library("asyncns", "asyncns_new")
CONFIG['LDSHARED'] = "$(CXX) -shared"
create_makefile("em_asyncns")
