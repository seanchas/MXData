load 'deploy/assets'

require "rvm/capistrano"
require 'bundler/capistrano'

set :application, "quotes"
set :repository,  "http://github.com/seanchas/MXData.git"
set :user,        :ror
set :runner,      :ror
set :use_sudo,    false
set :scm, :git
set :branch, "develop"

set :deploy_to,   "/export/depo/ror/linux/appservers/#{application}"
set :deploy_via,  :copy

set :rvm_ruby_string, "1.9.2@quotes"

server "beta", :app, :web, :primary => true

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

configuration = [
  '.env'
]

namespace :deploy do

  task :update_configuration, :roles => :app do
    configuration.each do |entry|
      run <<-CMD
        if [ -f #{release_path}/#{entry} ]; then rm -f #{release_path}/#{entry}; fi; ln -s #{shared_path}/rails/#{entry} #{release_path}/#{entry}
      CMD
    end
  end
  
end

before "deploy:finalize_update", "deploy:update_configuration"
