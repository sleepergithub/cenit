module Setup
  class HandlebarsConverter < ConverterTransformation
    include TemplateConverter

    build_in_data_type.referenced_by(:namespace, :name)

    def execute(options)
      handlebars = Handlebars::Handlebars.new
      result = handlebars.compile(options[:code]).call(source: options[:source].to_hash(include_id: true))
      options[:target] = options[:target_data_type].new_from(result)
    end
  end
end
