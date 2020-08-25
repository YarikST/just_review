# frozen_string_literal: true

require 'spec_helper'

describe ReferralPrograms::Base do
  describe '#consultation' do
    %w[Chroniccarecoaching Physicaltherapy Providerreferral].each do |class_name|
      it "creates for #{class_name}" do
        expect(ReferralPrograms.program(class_name)).not_to be nil
      end
    end
  end
end
