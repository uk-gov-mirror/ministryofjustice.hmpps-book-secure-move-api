# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FrameworkResponse::Array do
  subject { create(:array_response) }

  it { is_expected.to validate_absence_of(:value_text) }
  it { is_expected.to validate_inclusion_of(:value_json).in_array(['Level 1', 'Level 2']) }

  it 'validates value presence when a record is updated if question required' do
    question = create(:framework_question, required: true)
    response = create(:array_response, value: nil, framework_question: question)

    expect(response).to validate_presence_of(:value).on(:update)
  end

  it 'does not validate value json presence when a record is updated if question required but dependent' do
    question = create(:framework_question, required: true)
    response = create(:array_response, value: nil, framework_question: question, parent: create(:string_response))

    expect(response).not_to validate_presence_of(:value_json).on(:update)
  end

  it 'does not validate value json inclusion if no options present on question' do
    question = create(:framework_question, required: true, options: [])
    response = create(:array_response, value: ['Some value'], framework_question: question)

    expect(response).not_to validate_inclusion_of(:value_text).in_array([])
  end

  describe '#value' do
    it 'returns the response value if type is array' do
      response = create(
        :array_response,
        value: ['Level 1', 'Level 2'],
      )

      expect(response.value).to contain_exactly('Level 1', 'Level 2')
    end

    it 'returns an empty response value if set as empty' do
      response = create(:array_response, value: [])

      expect(response.value).to be_empty
    end

    it 'defaults to an empty response value if set to nil' do
      response = create(:array_response, value: nil)

      expect(response.value).to be_empty
    end
  end

  describe '#option_selected?' do
    it 'returns true if option matches any option selected' do
      response = create(
        :array_response,
        value: ['Level 1', 'Level 2'],
      )

      expect(response.option_selected?('Level 2')).to be(true)
    end

    it 'returns false if option does not match any option selected' do
      response = create(
        :array_response,
        value: ['Level 1', 'Level 2'],
      )

      expect(response.option_selected?('Level 3')).to be(false)
    end
  end
end