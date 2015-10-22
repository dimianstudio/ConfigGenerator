require 'config_generator/version'
require 'yaml'
require 'active_support/core_ext/object/blank'

class Hash
  def flatten_each(prefix = [], &blk)
    each do |k, v|
      if v.is_a?(Hash)
        v.flatten_each(prefix + [k], &blk)
      else
        yield prefix + [k], v
      end
    end
  end

  def deep_flatten(join_symbol = '/')
    {}.tap do |result|
      flatten_each do |k, v|
        result[k.join(join_symbol)] = v
      end
    end
  end
end

module ConfigGenerator
  class Base
    def initialize(project_path)
      @project_path = project_path
      @app_config = YAML.load(File.read("#{@project_path}/app_config.yml"))
      @errors = {}
    end

    def environments
      @environments ||= @app_config['environments'] || []
    end

    def generate_file
      if valid?
        File.open(config_path, 'w+') { |f| f.write(file_contents) }
      else
        @errors.each do |key, value|
          puts "#{config_file} - #{error_messages[key].call(value)}"
        end
      end
    end

    protected

    def config_file
      raise NotImplementedError, 'config_file is not implemented'
    end

    def config_path
      @project_path + '/config/' + config_file
    end

    def config_section
      @config_section ||= @app_config[config_file]
    end

    def required_keys
      []
    end

    def default_options
      {}
    end

    def error_messages
      {
        missing_environments: ->(value) { "Provide at least one environment." },
        missing_keys: ->(value) { "Fill missing values #{value.map { |k| "'#{k}'" }.join(', ')}." }
      }
    end

    def validate_config!
      @errors[:missing_environments] = true unless environments.present?

      missing_keys = required_keys - (config_section.keys + config_section.deep_flatten('.').keys)
      @errors[:missing_keys] = missing_keys if missing_keys.present?
    end

    def valid?
      validate_config!
      @errors.empty?
    end

    def file_contents
      raise NotImplementedError, 'file_contents is not implemented'
    end
  end
end