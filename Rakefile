begin
  require 'jeweler'
rescue LoadError
  raise "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

Jeweler::Tasks.new do |s|
  s.name = "em-asyncns"
  s.summary = "Resolve domain names from EventMachine with libasyncns"
  s.email = "stephan@spaceboyz.net"
  s.homepage = "http://github.com/astro/em-asyncns"
  s.description = "libasyncns binding for EventMachine"
  s.authors = ["Stephan Maka"]
  s.files =  FileList["[A-Z]*", "{bin,generators,ext,lib,test}/**/*"]
  s.extensions << 'ext/em_asyncns/extconf.rb'
  s.add_dependency 'eventmachine'
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList["spec/**/*"]
  t.spec_opts = %w(-cfn)
end
task :spec => :compile

require 'rake/extensiontask'
e = Rake::ExtensionTask.new('em_asyncns')
e.source_pattern = "*.{cc,h}"
