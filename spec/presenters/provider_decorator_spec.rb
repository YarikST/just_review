require 'spec_helper'

describe ProviderDecorator do
  let(:provider) do
    Provider.new(
        first_name: 'Julius',
        last_name: 'Hibbert',
        middle_name: 'M.',
        salutation: 'Dr.',
        suffix: ''
    )
  end

  describe '#name' do
    it 'formats name using default' do
      expect(ProviderDecorator.new(provider).name).to eq('Julius Hibbert')
    end
  end
end
