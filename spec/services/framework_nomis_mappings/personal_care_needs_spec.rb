# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FrameworkNomisMappings::PersonalCareNeeds do
  it 'builds a framework NOMIS mapping for active personal care needs from NOMIS' do
    allow(NomisClient::PersonalCareNeeds).to receive(:get).and_return([nomis_personal_care_need])
    mappings = described_class.new(prison_number: 'A9127EK').call

    expect(mappings.first).to be_a(FrameworkNomisMapping)
  end

  it 'sets the correct attributes on framework NOMIS mappings' do
    allow(NomisClient::PersonalCareNeeds).to receive(:get).and_return([nomis_personal_care_need])
    mappings = described_class.new(prison_number: 'A9127EK').call

    expect(mappings.first).to have_attributes(
      raw_nomis_mapping: nomis_personal_care_need,
      code_type: 'personal_care_need',
      code: 'ACCU9',
      code_description: 'Preg, acc under 9mths',
      start_date: Date.parse('2010-06-21'),
      end_date: Date.parse('2100-06-21'),
    )
  end

  it 'imports personal care needs if end date is not set' do
    allow(NomisClient::PersonalCareNeeds).to receive(:get).and_return([nomis_personal_care_need])
    mappings = described_class.new(prison_number: 'A9127EK').call

    expect(mappings.count).to eq(1)
  end

  it 'ignores personal care needs that have ended' do
    allow(NomisClient::PersonalCareNeeds).to receive(:get).and_return([nomis_personal_care_need(end_date: '2010-06-21')])
    mappings = described_class.new(prison_number: 'A9127EK').call

    expect(mappings).to be_empty
  end

  it 'ignores personal care needs with status "I" (recovered)' do
    allow(NomisClient::PersonalCareNeeds).to receive(:get).and_return([nomis_personal_care_need(problem_status: 'I')])
    mappings = described_class.new(prison_number: 'A9127EK').call

    expect(mappings).to be_empty
  end

  it 'ignores personal care needs with status "EBS" (Expired Body Scan Entry)' do
    allow(NomisClient::PersonalCareNeeds).to receive(:get).and_return([nomis_personal_care_need(problem_status: 'EBS')])
    mappings = described_class.new(prison_number: 'A9127EK').call

    expect(mappings).to be_empty
  end

  it 'returns an empty result if no prison number supplied' do
    allow(NomisClient::PersonalCareNeeds).to receive(:get).and_return([nomis_personal_care_need])
    mappings = described_class.new(prison_number: nil).call

    expect(mappings).to be_empty
  end

  it 'returns an empty result if importing NOMIS personal care needs fails' do
    oauth2_response = instance_double('OAuth2::Response', body: '{}', parsed: {}, status: '', 'error=': '')
    allow(NomisClient::PersonalCareNeeds).to receive(:get).and_raise(OAuth2::Error, oauth2_response)
    mappings = described_class.new(prison_number: 'A9127EK').call

    expect(mappings).to be_empty
  end

  it 'returns an empty result if no personal care needs found for prison number' do
    allow(NomisClient::PersonalCareNeeds).to receive(:get).and_return([])
    mappings = described_class.new(prison_number: 'A9127EK').call

    expect(mappings).to be_empty
  end

  def nomis_personal_care_need(start_date: '2010-06-21', end_date: '2100-06-21', problem_status: 'ON')
    {
      problem_code: 'ACCU9',
      problem_status: problem_status,
      problem_description: 'Preg, acc under 9mths',
      start_date: start_date,
      end_date: end_date,
      offender_no: '321',
    }.with_indifferent_access
  end
end
