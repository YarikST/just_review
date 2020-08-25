# frozen_string_literal: true

require 'spec_helper'

describe ReferralPrograms::Chroniccarecoaching do
  subject { described_class.new(answer_cd: 'PREFIX_ChroniccarecoachinG') }

  describe '#program' do
    it 'returns program' do
      consultation = described_class.new(answer_cd: 'PREFIX_ChroniccarecoachinG', program: 'program')
      expect(consultation.program).not_to be nil
    end

    it 'returns nil' do
      expect(subject.program).to be nil
    end
  end

  describe '#recommendation_text' do
    it 'gets text' do
      expect(subject.recommendation_text).to eq 'Your provider recommends Health Coaching by Vida.'
    end
  end

  describe '#recommendation_url' do
    it 'gets url' do
      url_helpers = double('url_helpers')

      expect(subject).to receive(:url_helpers).and_return url_helpers
      expect(url_helpers).to receive(:information_vida_path)

      subject.recommendation_url
    end
  end
end
