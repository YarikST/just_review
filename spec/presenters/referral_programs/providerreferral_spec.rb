# frozen_string_literal: true

require 'spec_helper'

describe ReferralPrograms::Providerreferral do
  subject { described_class.new(answer_cd: 'PREFIX_ProviderreferraL') }

  describe '#recommendation_text' do
    it 'gets text' do
      expect(subject.recommendation_text).to eq 'Your provider recommends Provider Referral.'
    end
  end

  describe '#recommendation_url' do
    it 'gets url' do
      url_helpers = double('url_helpers')

      expect(subject).to receive(:url_helpers).and_return url_helpers
      expect(url_helpers).to receive(:information_provider_referral_path)

      subject.recommendation_url
    end
  end
end
