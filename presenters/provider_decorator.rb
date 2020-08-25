class ProviderDecorator < SimpleDelegator
  include Shared::ProvidersHelper

  def name(options = {})
    provider_name(self, options)
  end
end
