# frozen_string_literal: true

require 'spec_helper'

describe Consultations::Base do
  describe '#consultation' do
    %w[BehavioralHealth Dermatology GeneralMedical Nutrition PrimaryCare].each do |class_name|
      it "creates for #{class_name}" do
        expect(Consultations.consultation(class_name)).not_to be nil
      end
    end
  end
end
