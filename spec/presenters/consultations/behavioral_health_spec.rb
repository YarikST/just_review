# frozen_string_literal: true

require 'spec_helper'

describe Consultations::BehavioralHealth do
  subject { described_class.new(specialty: 'Behavioral Health') }

  describe '#recommendation_text' do
    context 'when Psychiatrist' do
      subject { described_class.new(feature: 'MD, DO Psychiatrist', specialty: 'Behavioral Health') }

      it 'gets text' do
        expect(subject.recommendation_text).to eq 'Your provider recommends that you request a visit with one of our psychiatrists for further treatment.'
      end
    end
    context 'when Therapist/Counselor' do
      subject { described_class.new(feature: 'Non MD, DO or Psychiatrist', specialty: 'Behavioral Health') }

      it 'gets text' do
        expect(subject.recommendation_text).to eq 'Your provider recommends that you request a visit with one of our therapists or counselors.'
      end
    end

    it 'gets text' do
      expect(subject.recommendation_text).to include('translation missing')
    end
  end
end
