module RailsAdmin
  module Models
    module Setup
      module NotebookAdmin
        extend ActiveSupport::Concern

        included do
          rails_admin do
            navigation_label 'Compute'
            weight 400
            object_label_method { :path }
          end
        end

      end
    end
  end
end
