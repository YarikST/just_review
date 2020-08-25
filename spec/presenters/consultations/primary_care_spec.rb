# frozen_string_literal: true

require 'spec_helper'

describe Consultations::PrimaryCare do
  subject { described_class.new(specialty: 'Primary Care') }

  describe '#recommendation_text' do
    it 'gets text' do
      expect(subject.recommendation_text).to eq 'Your provider recommends that you request a visit with one of our primary care providers.'
    end
  end
end
