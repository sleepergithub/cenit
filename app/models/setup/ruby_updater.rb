module Setup
  class RubyUpdater < UpdaterTransformation
    include WithSourceOptions
    include RubyCodeTransformation

    build_in_data_type.referenced_by(:namespace, :name)

    field :source_handler, type: Mongoid::Boolean

    def validates_configuration
      remove_attribute(:source_handler) unless source_handler
      super
    end

    def source_key_options
      opts = super
      opts.merge!(
        data_type_key: :target_data_type,
        sources_key: :targets,
        source_key: :target,
        bulk: source_handler
      )
      opts
    end
  end
end
