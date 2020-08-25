# frozen_string_literal: true

require 'spec_helper'

describe Consultations::GeneralMedical do
  subject { described_class.new(specialty: 'General Medical') }

  describe '#recommendation_text' do
    it 'gets text' do
      expect(subject.recommendation_text).to eq 'Your provider recommends that you request a visit with one of our general medical providers.'
    end
  end
end
