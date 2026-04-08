require 'yaml'
require 'fileutils'

@config = YAML.safe_load_file(File.join(File.dirname(__FILE__), "config.yml"), symbolize_names: true)


def require_properties(*props)
   props.each { |prop| raise "missing property: #{prop}" unless @config.has_key?(prop) }
end

desc "updates to latest code and restarts service"
task :update => ["service:stop", :pull, :install, "service:start"]

namespace :service do
   desc "stop the service"
   task :stop do
      require_properties(:service_name)
      sh "sudo systemctl stop #{@config[:service_name]}"
   end

   desc "start the service"
   task :start do
      require_properties(:service_name)
      sh "sudo systemctl start #{@config[:service_name]}"
   end
end

desc "remove gems"
task :clean do
   FileUtils.rm_r("vendor") if File.exist?("vendor")
end

desc "get the latest code"
task :pull do
   require_properties(:git_remote, :git_branch)
   sh "git pull #{@config[:git_remote]} #{@config[:git_branch]}"
end

desc "install gems"
task :install do
   sh "bundle install"
end
