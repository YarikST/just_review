# frozen_string_literal: true

module WorkflowQueues
  module Actions
    class Base
      attr_reader :workflow_queue, :completing_person

      def initialize(options = {})
        @workflow_queue               = options[:workflow_queue]
        @completing_person            = options[:completing_person]
      end

      def call
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end
  end
end

=begin

before ->

def assign(*args)
  result = super
  if result
    self.pending_til = nil
    self.owner = args[0]
    self.save!
    create_detail(args[0])
  end
  self
end

def unassign(*args)
  result = super
  if result
    self.owner = nil
    self.save!
    create_detail(args[0])
  end
  self
end

def revoke(*args)
  result = super
  if result
    self.pending_til = nil
    self.owner = nil
    self.save!
    create_detail(args[0])
  end
  self
end

def complete(completing_person:, escalation_reason_cd: nil, grievance_category_cd: nil, case_summary_resolution: nil, case_origination_cd: nil, lab_note: nil)
  if super
    options = { lab_note: lab_note }
    WorkflowQueueCompleterWorker.perform_async(id, completing_person.id, completing_person.class.name, escalation_reason_cd, options)
  end
  complete_child_items(completing_person)
  NurseAction.complete_request_for_excuse_note(actor, completing_person) if actor.kind_of?(NurseAction) && actor.nurse_action_cd.eql?('NURSEACTION_EXCUSENOTE')
  update_attributes(grievance_category_cd: grievance_category_cd) if grievance_category_cd.present?
  update_attributes(case_summary_resolution: case_summary_resolution) unless case_summary_resolution.nil?
  update_attributes(case_origination_cd: case_origination_cd) if case_origination_cd.present?
  self
end



after ->

def complete(params={})
  tap { WorkflowQueues::Actions::Complete.new(params.merge({workflow_queue: self})).call if super }
end

def assign(*args)
  tap { WorkflowQueues::Actions::Assign.new({workflow_queue: self, completing_person: args[0]}).call if super }
end

def unassign(*args)
  tap { WorkflowQueues::Actions::Unassign.new({workflow_queue: self, completing_person: args[0]}).call if super }
end

def revoke(*args)
  tap { WorkflowQueues::Actions::Revoke.new({workflow_queue: self, completing_person: args[0]}).call if super }
end

def complete(params={})
  tap { WorkflowQueues::Actions::Complete.new(params.merge({workflow_queue: self})).call if super }
end=end
