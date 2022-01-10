module Setup
  class Validator
    include CenitScoped
    include NamespaceNamed
    include ClassHierarchyAware
    include SharedEditable

    abstract_class true

    build_in_data_type.referenced_by(:namespace, :name)

    before_save :validates_configuration

    def validates_configuration
      abort_if_has_errors
    end

    def validate_data(_data)
      fail NotImplementedError
    end

    def validate_file_record(file)
      validate_data(file.data)
    end

    def data_format
      nil
    end

    def content_type
      nil
    end

  end
end
