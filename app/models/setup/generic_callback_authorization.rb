module Setup
  class GenericCallbackAuthorization < Authorization
    include CenitScoped
    include CallbackAuthorization

    build_in_data_type.referenced_by(:namespace, :name)

    belongs_to :callback_resolver, class_name: Setup::Algorithm.to_s, inverse_of: nil
    belongs_to :parameters_signer, class_name: Setup::Algorithm.to_s, inverse_of: nil

    def check
      errors.add(:callback_resolver, "can't be blank") unless callback_resolver
      %w(callback_resolver parameters_signer).each do |relation|
        next unless (alg = send(relation))
        errors.add(relation.to_sym, " must have two parameters") unless alg.parameters.size == 2
      end
      super
    end

    def callback_key
      ((template = template_parameters.where(key: 'callback_key').first) && template.value.presence) || :redirect_uri
    end

    def authorize_url(params)
      templates = {}
      if (cenit_token = params.delete(:cenit_token))
        templates['callback_token'] = cenit_token.token
      end
      uri = URI.parse(authorization_endpoint)
      uri.query = [uri.query, authorize_params(params, templates).to_param].compact.join('&')
      uri.to_s
    end

    def accept_callback?(_params)
      true
    end

    def resolve(params)
      fail "Callback resolver is not present" unless callback_resolver
      templates = template_parameters_hash
      callback_resolver.run([params, templates])
      fill_from({template_parameters: templates.map { |key, value| { key: key, value: value } }}, add_only: true, reset: :template_parameters)
      self.authorized_at = Time.now
    end

    def sign_params(params, template_parameters = {})
      parameters_signer.run([params, template_parameters]) if parameters_signer
    end
  end
end
