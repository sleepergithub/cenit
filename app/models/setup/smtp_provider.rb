module Setup
  class SmtpProvider
    include CenitScoped
    include NamespaceNamed

    build_in_data_type.referenced_by(:namespace, :name)

    field :address, type: String, default: 'smtp.gmail.com'
    field :port, type: Integer, default: 587
    field :domain, type: String, default: 'gmail.com'
    field :enable_starttls_auto, type: Mongoid::Boolean, default: true

  end
end
