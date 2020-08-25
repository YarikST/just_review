# frozen_string_literal: true

module History
  extend ActiveSupport::Concern

  included do
    after_update  :save_version, if: :versioning_record?
    after_destroy :save_version, if: :versioning_record?

    # There are default value for mapping
    history_fields_mapping({})
    history_additionals_fields_mapping({})
    history_previous_fields_mapping({})
  end

  def save_version
    history= history_model.new(history_attributes)
    unless history.save
      History.error_log history_model: history_model, context_errors: history.errors.inspect
    end
  end

  def versioning_record?
    # Each model which includes this module needs to implement this method for
    # itself. Below is an example of what it might look like assuming all
    # notable attribute changes trigger the creation of a new version:
    #
    #  tracking_object.destroyed? || changed_tracking_fields || tracking_object.notably_changed? / (Rails5.2 tracking_object.saved_change_to_notably?)

    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def changed_tracking_fields
    (changed & history_fields).present?
  end

  def history_attributes
    history_fields.each_with_object({}) do |field, hsh|
      hsh[mapping_fields(history_fields_mapping, field)] = send mapping_previous_fields(mapping_fields(history_additionals_fields_mapping, field))
    end
  end

  def mapping_fields fields, field
    fields[field] || field
  end

  def mapping_previous_fields field
    history_previous_fields_mapping[field] || "#{field}_was"
  end

  module ClassMethods
    # Each model which includes this module needs to implement this method for
    # itself. Below is an example of what it might look like assuming *UserLog*
    # class is responsible for saving version
    #
    # history_model UserLog
    def history_model model
      define_method(:history_model) do
        model
      end
    end

    # Each model which includes this module needs to implement this method for
    # itself. Below is an example of what it might look like assuming *full_name*, *email*
    # attributes change trigger the creation of a new version and them need to save in *history_model*
    #
    # history_fields :full_name, :email
    def history_fields *fields
      history_fields = fields.map(&:to_s)

      define_method(:history_fields) do
        history_fields
      end
    end

    # Each object which includes this module can to implement this method for
    # itself. Below is an example of what it might look like assuming attribute *full_name* from the model does not exist in *history_model*
    # but we have *user_name* field for saving this data
    #
    # history_fields_mapping full_name: :user_name
    def history_fields_mapping fields
      history_fields_mapping = fields.with_indifferent_access

      define_method(:history_fields_mapping) do
        history_fields_mapping
      end
    end

    # Each object which includes this module can to implement this method for
    # itself. Below is an example of what it might look like assuming attribute *actor* from the *history_model* related to *member* in model
    #
    # history_fields_mapping actor: :member
    #
    # Note: Active record has itself method, it works like ruby a self method
    # so you can create actor: :itself
    def history_additionals_fields_mapping fields
      history_additionals_fields_mapping = fields.with_indifferent_access

      define_method(:history_additionals_fields_mapping) do
        history_additionals_fields_mapping
      end
    end

    # Each object which includes this module can to implement this method for
    # itself. Below is an example of what it might look like assuming attribute *actor* from the *history_model*
    # needs saving the same value all time or preview value created a different way than *_was* methods in Active Record
    #
    # history_previous_fields_mapping actor: :itself
    def history_previous_fields_mapping fields
      history_previous_fields_mapping = fields.with_indifferent_access

      define_method(:history_previous_fields_mapping) do
        history_previous_fields_mapping
      end
    end
  end

  def self.error_log(history_model:, context_errors:)
    err_msg = "Error while saving History for #{history_model}: #{context_errors}"

    Rails.logger.error err_msg
    Airbrake.notify( error_class: history_model, error_message: err_msg )
  end
end
