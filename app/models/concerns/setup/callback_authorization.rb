module Setup
  module CallbackAuthorization
    extend ActiveSupport::Concern

    include Parameters
    include WithTemplateParameters

    included do
      field :authorized_at, type: DateTime

      belongs_to :client, class_name: Setup::AuthorizationClient.to_s, inverse_of: nil

      parameters :parameters, :template_parameters

      before_save :check!
    end

    def check
      errors.add(:client, "can't be blank") unless client
      super
    end

    def each_template_parameter(&block)
      return unless block
      template_parameters.each do |parameter|
        block.call(parameter.name, parameter.value)
      end
      method_missing(:each_template_parameter, &block)
    end

    def provider
      client&.provider
    end

    def authorization_endpoint
      provider && template_value_of(provider.authorization_endpoint)
    end

    def authorized?
      authorized_at.present?
    end

    def callback_key
      fail NotImplementedError
    end

    def callback_url
      "#{Cenit.homepage}/oauth/callback"
    end

    def callback_params
      { callback_key.to_s => callback_url }
    end

    def authorize_params(params = {}, template_parameters = {})
      params = callback_params.merge(params)
      conformed_parameters(template_parameters).each { |key, value| params[key.to_sym] = value }
      params
    end

    def authorize_url(_params)
      fail NotImplementedError
    end

    def resolve!(params)
      resolve(params)
      save || raise(errors.full_messages.to_sentence)
    end

    def resolve(_params)
      fail NotImplementedError
    end

    def cancel!
      cancel
      save
    end

    def cancel
      self.authorized_at = nil
    end

    def accept_callback?(_params)
      fail NotImplementedError
    end

    def inject_template_parameters(hash)
      client && client.try(:inject_template_parameters, hash)
      hash[callback_key.to_s] ||= callback_url
    end
  end
end
