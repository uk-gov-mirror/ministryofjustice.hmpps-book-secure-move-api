# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PersonEscortRecordsController do
  describe 'GET /person_escort_records/:person_escort_record_id' do
    include_context 'with supplier with spoofed access token'

    let(:response_json) { JSON.parse(response.body) }
    let(:framework_question) { build(:framework_question, section: 'risk-information') }
    let(:framework_response) { build(:string_response, framework_question: framework_question) }
    let(:framework) { create(:framework, framework_questions: [framework_question]) }
    let(:person_escort_record) { create(:person_escort_record, framework_responses: [framework_response]) }
    let(:person_escort_record_id) { person_escort_record.id }

    before do
      get "/api/v1/person_escort_records/#{person_escort_record_id}", headers: headers, as: :json
    end

    context 'when successful' do
      let(:schema) { load_yaml_schema('get_person_escort_record_responses.yaml') }
      let(:data) do
        {
          "id": person_escort_record.id,
          "type": 'person_escort_records',
          "attributes": {
            "version": person_escort_record.framework.version,
            "status": 'in_progress',
          },
          "meta": {
            'section_progress' => [
              {
                "key": 'risk-information',
                "status": 'completed',
              },
            ],
          },
          "relationships": {
            "profile": {
              "data": {
                "id": person_escort_record.profile.id,
                "type": 'profiles',
              },
            },
            "framework": {
              "data": {
                "id": person_escort_record.framework.id,
                "type": 'frameworks',
              },
            },
            "responses": {
              "data": [
                {
                  "id": framework_response.id,
                  "type": 'framework_responses',
                },
              ],
            },
          },
        }
      end

      it_behaves_like 'an endpoint that responds with success 200'

      it 'returns the correct data' do
        expect(response_json).to include_json(data: data)
      end
    end

    context 'when unsuccessful' do
      let(:schema) { load_yaml_schema('error_responses.yaml') }

      context "when attempting to access another move's journey" do
        let(:person_escort_record_id) { SecureRandom.uuid }
        let(:detail_404) { "Couldn't find PersonEscortRecord with 'id'=#{person_escort_record_id}" }

        it_behaves_like 'an endpoint that responds with error 404'
      end
    end
  end
end
