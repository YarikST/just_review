class AltProviderId < ActiveRecord::Base
  include ParanoidModel
  include AttributeScopesAccessors
  include History

  self.primary_key = :alt_provider_id

  belongs_to :provider, foreign_key: :provider_id
  belongs_to :ref_issuing_body, primary_key: :issuing_body_cd, foreign_key: :issuing_body_cd

  has_many :provider_credential_verification_logs, as: :credential_object

  delegate :country_cd, to: :ref_issuing_body
  delegate :teladoc_doctor?, to: :provider

  validates_presence_of :provider_id
  validates_presence_of :alt_id

  validates_format_of :alt_id, :with => /\A\d{10}\z/, if: [:teladoc_doctor?, :npi?], message: 'NPI credentials not valid'

  validate :issuing_body_code_uniqueness

  ISSUING_BODY_TYPES = {
    dea: 'PROVIDERID_DEA',
    npi: 'PROVIDERID_NPI',
    medicare: 'PROVIDERID_MEDICARE',
    spi: 'PROVIDERID_SPI'
  }

  attribute_scopes_accessors :issuing_body_cd, ISSUING_BODY_TYPES

  history_model ProviderCredentialVerificationLog
  history_fields :provider_id, :issuing_body_cd, :alt_id, :expiration_dt, :verification_dt, :credential_object
  history_fields_mapping alt_id: "license"
  history_additionals_fields_mapping credential_object: "itself"
  history_previous_fields_mapping itself: "itself"


  def issuing_body_name
    ISSUING_BODY_TYPES.key(issuing_body_cd).to_s.titleize.upcase
  end

  def self.issuing_body_types
    ISSUING_BODY_TYPES
  end

  def versioning_record?
    return unless $rollout.active?(:history_alt_provider_id)

    !alt_provider_id_changed? && ( destroyed? || changed_tracking_fields )
  end

  private

  def issuing_body_code_uniqueness
    scope = self.class.where(provider_id: provider_id, issuing_body_cd: issuing_body_cd)
    scope = scope.where("alt_provider_id != ?", self.id) if persisted?
    if scope.exists?
      self.errors[:issuing_body_cd] << "#{issuing_body_name} already in use for this provider"
    end
  end
end
