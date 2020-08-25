# frozen_string_literal: true

require 'spec_helper'

describe MessagePresenter do
  describe '#internal_referral_recommendation_text' do
    it 'returns blank when referral blank' do
      expect(subject.internal_referral_recommendation_text(nil)).to eq ''
    end

    it 'returns blank when consultation blank' do
      specialty = 'Class Consultation'
      expect(subject.internal_referral_recommendation_text(specialty: specialty)).to eq ''
    end

    it 'calls recommendation_text' do
      specialty               = 'Class Consultation'
      feature                 = 'feature'
      class_consultation      = double 'ClassConsultation'
      consultation            = double 'Consultation'
      referral                = { specialty: specialty, feature: feature }

      expect(Consultations).to receive(:consultation).with('ClassConsultation').and_return class_consultation
      expect(class_consultation).to receive(:new).with(feature: feature, specialty: specialty).and_return consultation
      expect(consultation).to receive(:recommendation_text)

      subject.internal_referral_recommendation_text(referral)
    end

    describe 'converts name to consultation' do
      ['Behavioral Health', 'Dermatology', 'General Medical', 'Nutrition', 'Primary Care'].each do |class_name|
        it "converts for #{class_name}" do
          class_consultation      = double 'ClassConsultation'
          consultation            = double 'Consultation'

          expect(Consultations).to receive(:consultation).and_return class_consultation
          expect(class_consultation).to receive(:new).and_return consultation
          expect(consultation).to receive(:recommendation_text)

          subject.internal_referral_recommendation_text(specialty: class_name)
        end
      end
    end
  end

  shared_examples 'converts name to program' do
    %w[PREFIX_CHRONICCARECOACHING PREFIX_PHYSICALTHERAPY PREFIX_PROVIDERREFERRAL].each do |class_name|
      it "converts for #{class_name}" do
        class_program      = double 'ClassProgram'
        program            = double 'Program'

        expect(ReferralPrograms).to receive(:program).and_return class_program
        expect(class_program).to receive(:new).and_return program
        expect(program).to receive(:recommendation_text)

        subject.partner_referral_recommendation_text(answer_cd: class_name)
      end
    end
  end

  describe '#partner_referral_recommendation_text' do
    it 'returns blank when referral blank' do
      expect(subject.partner_referral_recommendation_text(nil)).to eq ''
    end

    it 'returns blank when program blank' do
      answer_cd = 'Prefix_ClassProgram'
      expect(subject.partner_referral_recommendation_text(answer_cd: answer_cd)).to eq ''
    end

    it 'calls recommendation_text' do
      answer_cd = 'Prefix_ClassProgram'
      class_program = double 'ClassProgram'
      program = double 'Program'
      referral = { answer_cd: answer_cd }

      expect(ReferralPrograms).to receive(:program).with('Classprogram').and_return class_program
      expect(class_program).to receive(:new).with(answer_cd: answer_cd).and_return program
      expect(program).to receive(:recommendation_text)

      subject.partner_referral_recommendation_text(referral)
    end

    it_behaves_like 'converts name to program'
  end

  describe '#partner_referral_recommendation_url' do
    it 'returns blank when referral blank' do
      expect(subject.partner_referral_recommendation_url(nil)).to eq ''
    end

    it 'returns blank when program blank' do
      answer_cd = 'Prefix_ClassProgram'
      expect(subject.partner_referral_recommendation_url(answer_cd: answer_cd)).to eq ''
    end

    it 'calls recommendation_url' do
      answer_cd = 'Prefix_ClassProgram'
      class_program = double 'ClassProgram'
      program = double 'Program'
      referral = { answer_cd: answer_cd }

      expect(ReferralPrograms).to receive(:program).with('Classprogram').and_return class_program
      expect(class_program).to receive(:new).with(answer_cd: answer_cd).and_return program
      expect(program).to receive(:recommendation_url)

      subject.partner_referral_recommendation_url(referral)
    end

    it_behaves_like 'converts name to program'
  end
end
