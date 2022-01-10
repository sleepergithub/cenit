require 'mongoid/userstamp'
require 'mongoid/userstamp/config'

module Setup
  module CrossOriginShared
    extend ActiveSupport::Concern

    include CenitScoped
    include CrossOrigin::CenitDocument
    include Mongoid::Userstamp
    include Mongoid::Tracer

    TRACING_IGNORE_ATTRIBUTES = [:created_at, :updated_at, :creator_id, :updater_id, :tenant_id, :origin]

    DEFAULT_ORIGINS = [
      -> { Cenit::MultiTenancy.tenant_model.current && [:default, :owner] }, :shared
    ]

    included do
      origins *Setup::CrossOriginShared::DEFAULT_ORIGINS

      build_in_data_type
        .excluding(:tenant)
        .including_polymorphic(:origin)
        .and_polymorphic(with_origin: true)

      shared_deny :delete

      trace_ignore TRACING_IGNORE_ATTRIBUTES

      belongs_to :tenant, class_name: Cenit::MultiTenancy.tenant_model_name, inverse_of: nil

      before_validation :validates_before

      before_destroy :validates_for_destroy
    end

    def delete(options = {})
      validates_for_destroy && super
    end

    def validates_for_destroy
      unless origin == :default
        errors.add(:base, "#{try(:custom_title) || try(:name) || "#{self.class}##{id}"} is shared")
      end
      errors.blank?
    end

    def validates_before
      self.tenant = Account.current if new_record? || tenant.nil?
    end

    def tracing?
      (shared? || self.class.data_type.trace_on_default) && super
    end

    def trace_action_attributes(action = nil)
      attrs = super
      attrs[:origin] = origin
      attrs
    end

    def not_shared?
      !shared?
    end

    def shared?
      origin != :default
    end

    def tenant_version
      if !Thread.current[:cenit_pins_off] && (pin = Setup::Pin.for(self)) && (trace = pin.trace)
        trace.target_after_action(self)
      else
        self
      end
    end

    def read_raw_attribute(name)
      if !(value = super).nil? &&
         (new_record? || !self.class.build_in_data_type.protecting?(name) ||
           (current_user = User.current) &&
             (current_user.account_ids.include?(tenant_id) ||
               current_user.super_admin?))
        value
      else
        nil
      end
    end

    def [](name)
      read_attribute(name)
    end

    module ClassMethods

      def shared_deny(*actions)
        @shared_denied_actions = Set.new(actions.flatten.map(&:to_sym))
      end

      def shared_denied_actions
        @shared_denied_actions || []
      end

      def shared_allow(*actions)
        @shared_allowed_actions = Set.new(actions.flatten.map(&:to_sym))
      end

      def shared_allowed_actions
        @shared_allowed_actions || []
      end

      def clear_config_for(tenant, ids)
        clear_pins_for(tenant, ids)
      end

      def clear_pins_for(tenant, ids)
        tenant.switch do
          Setup::Pin.where(target_model_name: mongoid_root_class, :target_id.in => ids).delete_all
        end
      end

      def super_count
        # current_account = Account.current
        # Account.current = nil
        # c = 0
        # Account.each do |account|
        #   Account.current = account
        #   c += where(origin: :default).count
        # end
        # Account.current = current_account
        # c + where(origin: :shared).count
        where(:origin.ne => :default).count
      end
    end
  end
end
