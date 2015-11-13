# ConfigGenerator

Generate Rails config files from one application.yml

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'config_generator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install config_generator

## Usage

Example of application.yml

```yaml
# Necessary environments. It's required key.
#
environments:
  - development
  - test

database_names: &database_names
  development: streamline_development
  test: streamline_test

###############################################################################

database.yml:
  # MySQL supports a reconnect flag in its connections - if set to true, then the client will try
  # reconnecting to the server before giving up in case of a lost connection.
  # You can now set reconnect = true for your MySQL connections in database.yml to get this
  # behavior from a Rails application.
  #
  # reconnect: true

  # List of databases for each environment. It is required key.
  #
  database_names:
    <<: *database_names

  # Active Record database connections are managed by ActiveRecord::ConnectionAdapters::ConnectionPool
  # which ensures that a connection pool synchronizes the amount of thread access to a limited number
  # of database connections. This limit defaults to 5 and can be configured in database.yml.
  #
  # pool: 5

  # Database credentials
  #
  username: root
  password:

  # Connection Preference
  #
  # socket: /tmp/mysql.sock
  # host: localhost
  # port: 3306

###############################################################################

mongoid.yml:
...
```

Example of database.yml generator 

```ruby
module ConfigGenerator
  class DatabaseYml < Base

    protected

    def required_keys
      %w(database_names username)
    end

    def default_options
      {
        'adapter' => 'mysql2',
        'encoding' => 'utf8'
      }
    end

    def config_file
      'database.yml'
    end

    def database_names
      @database_names ||= config_section.delete('database_names') || {}
    end

    def error_messages
      super.merge(
        missing_db_for_environments: ->(value) { "Provide DB name for environments: #{value.map { |k| "'#{k}'" }.join(', ')}." }
      )
    end

    def validate_config!
      super

      return if database_names.empty?

      missing_db_for_environments = []
      environments.each do |environment|
        next if database_names[environment].present?
        missing_db_for_environments << environment
      end

      if missing_db_for_environments.present?
        @errors[:missing_db_for_environments] = missing_db_for_environments
      end
    end

    def file_contents
      environments.each_with_object({}) do |environment, result|
        options = config_section.merge('database' => database_names[environment])
        result[environment] = default_options.merge(options)
      end.to_yaml
    end
  end
end
```

and just execute after

```ruby
ConfigGenerator::DatabaseYml.new(Rails.root.to_s).generate_file
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dimianstudio/config_generator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

