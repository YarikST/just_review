# frozen_string_literal: true

require 'consultations/base'
require 'referral_programs/base'

class MessagePresenter
  def internal_referral_recommendation_text(referral)
    return '' unless referral.present?

    class_consultation = Consultations.consultation convert_specialty_to_class_name(referral[:specialty])
    return '' unless class_consultation.present?

    consultation = class_consultation.new(feature: referral[:feature], specialty: referral[:specialty])

    consultation.recommendation_text
  end

  def partner_referral_recommendation_text(referral)
    return '' unless referral.present?

    class_program = ReferralPrograms.program convert_answer_cd_to_class_name(referral[:answer_cd])
    return '' unless class_program.present?

    program = class_program.new(answer_cd: referral[:answer_cd])

    program.recommendation_text
  end

  def partner_referral_recommendation_url(referral)
    return '' unless referral.present?

    class_program = ReferralPrograms.program convert_answer_cd_to_class_name(referral[:answer_cd])
    return '' unless class_program.present?

    program = class_program.new(answer_cd: referral[:answer_cd])

    program.recommendation_url
  end

  private

  def convert_answer_cd_to_class_name(answer_cd)
    answer_cd.split('_').last.downcase.camelize
  end

  def convert_specialty_to_class_name(specialty)
    specialty.gsub(' ', '')
  end
end



=begin

how it was before ->

def internal_referral_recommendation_text(referral)
  return "" unless referral.present?
  case referral[:specialty]
  when "General Medical"
    "Your provider recommends that you request a visit with one of our general medical providers."
  when "Dermatology"
    "Your provider recommends that you request a visit with one of our dermatologists."
  when "Nutrition"
    "Your provider recommends that you request a visit with one of our dietitians."
  when "Behavioral Health"
    if TeladocConstants::Referral::INTERNAL_PROVIDER_SKILLS[referral[:feature]] == "Psychiatrist"
      "Your provider recommends that you request a visit with one of our psychiatrists for further treatment."
    else
      "Your provider recommends that you request a visit with one of our therapists or counselors."
    end
  else
    ''
  end


now you can use like this ->

- referrals.each do |primary_partner_referral|
  = @message_presenter.partner_referral_recommendation_text(primary_partner_referral)
  p.referral_button
    = link_to "Get Started",
            @message_presenter.partner_referral_recommendation_url(primary_partner_referral),
            class: "purple-button"

end=end
