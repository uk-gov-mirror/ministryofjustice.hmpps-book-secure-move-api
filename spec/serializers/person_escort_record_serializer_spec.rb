# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PersonEscortRecordSerializer do
  subject(:serializer) { described_class.new(person_escort_record) }

  let(:person_escort_record) { create(:person_escort_record) }
  let(:result) { ActiveModelSerializers::Adapter.create(serializer, include: includes).serializable_hash }
  let(:includes) { {} }

  it 'contains a `type` property' do
    expect(result[:data][:type]).to eq('person_escort_records')
  end

  it 'contains an `id` property' do
    expect(result[:data][:id]).to eq(person_escort_record.id)
  end

  it 'contains a `status` attribute' do
    expect(result[:data][:attributes][:status]).to eq('in_progress')
  end

  it 'contains a `version` attribute' do
    expect(result[:data][:attributes][:version]).to eq(person_escort_record.framework.version)
  end

  it 'contains a `confirmed_at` attribute' do
    expect(result[:data][:attributes][:confirmed_at]).to eq(person_escort_record.confirmed_at)
  end

  it 'contains a `printed_at` attribute' do
    expect(result[:data][:attributes][:printed_at]).to eq(person_escort_record.printed_at)
  end

  it 'contains a `profile` relationship' do
    expect(result[:data][:relationships][:profile][:data]).to eq(
      id: person_escort_record.profile.id,
      type: 'profiles',
    )
  end

  it 'contains a `framework` relationship' do
    expect(result[:data][:relationships][:framework][:data]).to eq(
      id: person_escort_record.framework.id,
      type: 'frameworks',
    )
  end

  it 'contains an empty `responses` relationship if no responses present' do
    expect(result[:data][:relationships][:responses][:data]).to be_empty
  end

  it 'contains a`responses` relationship with framework responses' do
    question = create(:framework_question)
    response = serializer.framework_responses.create!(type: 'FrameworkResponse::String', framework_question: question)

    expect(result[:data][:relationships][:responses][:data]).to contain_exactly(
      id: response.id,
      type: 'framework_responses',
    )
  end

  it 'contains an empty `flags` relationship if no flags present' do
    expect(result[:data][:relationships][:flags][:data]).to be_empty
  end

  it 'contains a`flags` relationship with framework response flags' do
    flag = create(:flag)
    create(:string_response, person_escort_record: person_escort_record, flags: [flag])

    expect(result[:data][:relationships][:flags][:data]).to contain_exactly(
      id: flag.id,
      type: 'framework_flags',
    )
  end

  describe 'meta' do
    it 'includes section progress' do
      question = create(:framework_question, framework: person_escort_record.framework, section: 'risk-information')
      create(:string_response, value: nil, framework_question: question, person_escort_record: person_escort_record)

      expect(result[:data][:meta][:section_progress]).to contain_exactly(
        key: 'risk-information',
        status: 'not_started',
      )
    end

    context 'with no questions' do
      it 'does not include includes section progress' do
        expect(result[:data][:meta][:section_progress]).to be_empty
      end
    end
  end

  context 'with include options' do
    let(:includes) { { responses: [:value, question: :key] } }
    let(:framework_response) { build(:object_response) }
    let(:person_escort_record) do
      create(:person_escort_record, framework_responses: [framework_response])
    end

    let(:expected_json) do
      [
        {
          id: framework_response.id,
          type: 'framework_responses',
          attributes: { value: framework_response.value },
        },
        {
          id: framework_response.framework_question.id,
          type: 'framework_questions',
          attributes: { key: framework_response.framework_question.key },
        },
      ]
    end

    it 'contains an included responses and question' do
      expect(result[:included]).to include_json(expected_json)
    end
  end
end
