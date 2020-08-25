# frozen_string_literal: true

require 'spec_helper'

describe ReferralPrograms::Physicaltherapy do
  subject { described_class.new(answer_cd: 'PREFIX_PhysicaltherapY') }

  describe '#recommendation_text' do
    it 'gets text' do
      expect(subject.recommendation_text).to eq 'Your provider recommends MSK Programs.'
    end
  end

  describe '#recommendation_url' do
    it 'gets url' do
      url_helpers = double('url_helpers')

      expect(subject).to receive(:url_helpers).and_return url_helpers
      expect(url_helpers).to receive(:information_telespine_physical_therapy_path)

      subject.recommendation_url
    end
  end
end
