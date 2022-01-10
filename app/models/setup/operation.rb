module Setup
  class Operation < Webhook

    build_in_data_type
      .including(:resource)
      .referenced_by(:resource, :method)

    deny :create

    belongs_to :resource, class_name: Setup::Resource.to_s, inverse_of: :operations

    trace_ignore :resource_id

    field :description, type: String
    field :method, type: String

    validates_uniqueness_of :method, scope: :resource

    parameters :parameters, :headers

    # trace_references :parameters, :headers

    validates_presence_of :resource, :method

    def tracing?
      false
    end

    def params_stack
      super.insert(-2, resource)
    end

    def scope_title
      resource&.custom_title
    end

    def namespace
      resource&.namespace || ''
    end

    def path
      resource&.path
    end

    def template_parameters
      resource&.template_parameters || []
    end

    def name
      "#{method.to_s.upcase} #{resource&.custom_title}"
    end

    def label
      "#{method.to_s.upcase}"
    end

    def title
      label
    end

    def connections
      resource&.connections.presence || super
    end

    class << self
      def namespace_enum
        Setup::Resource.namespace_enum
      end

      def search_properties_selector(query)
        {
          :resource_id.in => Setup::Resource.search(query).limit(25).collect(&:id)
        }
      end
    end

    protected

    def conforms(field, template_parameters = {}, base_hash = nil)
      if resource
        base_hash = resource.conforms(field, template_parameters, base_hash)
      end
      super
    end

  end
end
