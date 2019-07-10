module RailsSettings
  class Base < Settings
    def rewrite_cache
      self.class.configuration.cache_store.fetch(cache_key, value)
    end

    def expire_cache
      self.class.configuration.cache_store.delete(cache_key)
    end

    def cache_key
      self.class.cache_key(var, thing)
    end

    class << self

      attr_accessor :configuration

      def configure
        self.configuration ||= Configuration.new
        yield(configuration)
      end

      def cache_prefix(&block)
        @cache_prefix = block
      end

      def cache_key(var_name, scope_object)
        scope = ["rails_settings_cached"]
        scope << @cache_prefix.call if @cache_prefix
        scope << "#{scope_object.class.name}-#{scope_object.id}" if scope_object
        scope << var_name.to_s
        scope.join("/")
      end

      def [](key)
        return super(key) unless rails_initialized?
        val = cache_store.fetch(cache_key(key, @object)) do
          super(key)
        end
        val
      end

      # set a setting value by [] notation
      def []=(var_name, value)
        super
        cache_store.write(cache_key(var_name, @object), value)
        value
      end

      def cache_store
        @cache_store ||= RailsSettings::Base.configuration.cache_store
      end

      class Configuration
        attr_accessor :cache_store
      end

    end
  end
end