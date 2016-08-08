namespace :redmine_tagging do

  desc 'Runs the plugins tests.'
  desc 'Runs the redmine_tagging plugin tests'
  Rake::TestTask.new :test do |t|
    t.libs << 'test'
    t.verbose = true
    t.warning  = false
    t.pattern = 'plugins/redmine_tagging/test/**/*_test.rb'
  end

end