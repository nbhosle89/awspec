require 'fileutils'
require 'yaml'

module Awspec
  class Setup
    def self.run
      generate_spec_helper
      generate_rakefile
      generate_dotgitignore
    end

    def self.generate_from_vpc(vpc_id)
      creds = YAML.load_file('spec/secrets.yml') if File.exist?('spec/secrets.yml')
      creds = YAML.load_file('secrets.yml') if File.exist?('secrets.yml')
      if creds
        Aws.config.update({
                            region: creds['region'],
                            credentials: Aws::Credentials.new(
                              creds['aws_access_key_id'],
                              creds['aws_secret_access_key'])
                          })
      end
      vpc = Awspec::Generator::Spec::Vpc.new
      puts vpc.generate_from_vpc(vpc_id)
      puts ''
      ec2 = Awspec::Generator::Spec::Ec2.new
      puts ec2.generate_from_vpc(vpc_id)
      puts ''
      rds = Awspec::Generator::Spec::Rds.new
      puts rds.generate_from_vpc(vpc_id)
      puts ''
      security_group = Awspec::Generator::Spec::SecurityGroup.new
      puts security_group.generate_from_vpc(vpc_id)
    end

    def self.generate_spec_helper
      content = <<-'EOF'
require 'awspec'
if File.exist?('secrets.yml')
  creds = YAML.load_file('secrets.yml')
  Aws.config.update({
                      region: creds['region'],
                      credentials: Aws::Credentials.new(
                        creds['aws_access_key_id'],
                        creds['aws_secret_access_key'])
                    })
end
EOF
      dir = 'spec'
      if File.exist? dir
        unless File.directory? dir
          $stderr.puts '!! #{dir} already exists and is not a directory'
        end
      else
        FileUtils.mkdir dir
        puts ' + #{dir}/'
      end

      if File.exist? 'spec/spec_helper.rb'
        $stderr.puts '!! spec/spec_helper.rb already exists'
      else
        File.open('spec/spec_helper.rb', 'w') do |f|
          f.puts content
        end
        puts ' + spec/spec_helper.rb'
      end
    end

    def self.generate_rakefile
      content = <<-'EOF'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new('spec')
task :default => :spec
EOF

      if File.exist? 'Rakefile'
        $stderr.puts '!! Rakefile already exists'
      else
        File.open('Rakefile', 'w') do |f|
          f.puts content
        end
        puts ' + Rakefile'
      end
    end

    def self.generate_dotgitignore
      content = <<-'EOF'
secrets.yml
EOF
      if File.exist? 'spec/.gitignore'
        $stderr.puts '!! spec/.gitignore already exists'
      else
        File.open('spec/.gitignore', 'w') do |f|
          f.puts content
        end
        puts ' + spec/.gitignore'
      end
    end
  end
end
