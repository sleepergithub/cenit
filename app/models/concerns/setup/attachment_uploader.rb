module Setup
  module AttachmentUploader
    extend ActiveSupport::Concern
    include Setup::UploaderHelper

    def attach(attachment)
      body = nil
      store_options = { on: self.attachment }
      if attachment.is_a?(Hash)
        attachment.each do |key, value|
          if key.to_s == 'body'
            body = value
          else
            store_options[key] = value
          end
        end
      end
      body ||= attachment
      store(body, store_options)
    end

    module ClassMethods
      def attachment_uploader(*args)
        if (uploader = args.first || Cenit.attachment_uploader_for(self))
          @attachment_uploader = uploader
          if uploader.respond_to?(:prepare_model)
            uploader.prepare_model(self)
          end
          mount_uploader :attachment, uploader
        end
        @attachment_uploader
      end
    end
  end
end
