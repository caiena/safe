require "rails/generators"
require "rails/generators/active_record"

module SAFE
  class InstallGenerator < ::Rails::Generators::Base
    include ::Rails::Generators::Migration

    desc "Generate config files and migrations for SAFE protocol"

    source_root File.expand_path("templates", __dir__)

    def self.namespace
      'safe:install'
    end

    def self.base_name
      'safe'
    end

    def self.next_migration_number(dirname)
      ::ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    def create_migration_file
      add_migration('create_safe_workflow_monitors')
      add_migration('create_safe_job_monitors')
      add_migration('create_safe_error_occurrences')
      add_migration('change_safe_error_occurrences')
    end

    #def create_initializer_file
      #create_file "config/initializers/safe.rb", "# Add initialization content here"
    #end

    private

    def add_migration(template)
      migration_dir = File.expand_path("db/migrate")
      if self.class.migration_exists?(migration_dir, template)
        ::Kernel.warn "Migration already exists: #{template}"
      else
        migration_template(
          "#{template}.rb.erb",
          "db/migrate/#{template}.rb",
          { migration_version: migration_version }
        )
      end
    end

    def migration_version
      major = ActiveRecord::VERSION::MAJOR
      if major >= 5
        "[#{major}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end

  end
end
