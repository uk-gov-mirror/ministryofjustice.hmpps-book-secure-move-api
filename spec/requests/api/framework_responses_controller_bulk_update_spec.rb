# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::FrameworkResponsesController do
  describe 'PATCH /person_escort_records/:per_id/framework_responses' do
    include_context 'with supplier with spoofed access token'

    subject(:bulk_update_framework_responses) do
      patch "/api/person_escort_records/#{per_id}/framework_responses", params: bulk_per_params, headers: headers, as: :json
    end

    let(:schema) { load_yaml_schema('patch_framework_response_responses.yaml') }
    let(:response_json) { JSON.parse(response.body) }
    let(:person_escort_record) { create(:person_escort_record, :in_progress) }
    let(:per_id) { person_escort_record.id }

    let(:framework_response) { create(:string_response, person_escort_record: person_escort_record) }
    let(:other_framework_response) { create(:string_response, person_escort_record: person_escort_record) }
    let(:framework_response_id) { framework_response.id }
    let(:other_framework_response_id) { other_framework_response.id }

    let!(:flag) { create(:framework_flag, framework_question: framework_response.framework_question, question_value: 'Yes') }
    let!(:other_flag) { create(:framework_flag, framework_question: other_framework_response.framework_question, question_value: 'No') }

    let(:value) { 'Yes' }
    let(:other_value) { 'No' }

    let(:bulk_per_params) do
      {
        data: [
          {
            id: framework_response_id,
            type: 'framework_responses',
            attributes: {
              value: value,
            },
          },
          {
            id: other_framework_response_id,
            type: 'framework_responses',
            attributes: {
              value: other_value,
            },
          },
        ],
      }
    end

    context 'when successful' do
      before { bulk_update_framework_responses }

      it_behaves_like 'an endpoint that responds with success 204'

      it 'updates PER status' do
        expect(person_escort_record.reload.status).to eq('completed')
      end

      it 'attaches flags to the responses' do
        expect(framework_response.framework_flags).to contain_exactly(flag)
        expect(other_framework_response.framework_flags).to contain_exactly(other_flag)
      end

      context 'when responses are strings' do
        it 'updates response values' do
          expect(framework_response.reload.value).to eq(value)
          expect(other_framework_response.reload.value).to eq(other_value)
        end
      end

      context 'when responses are arrays' do
        let(:framework_response) { create(:array_response, person_escort_record: person_escort_record) }
        let(:other_framework_response) { create(:array_response, person_escort_record: person_escort_record) }
        let(:value) { ['Level 1', 'Level 2'] }
        let(:other_value) { ['Level 1'] }

        it 'updates response values' do
          expect(framework_response.reload.value).to eq(value)
          expect(other_framework_response.reload.value).to eq(other_value)
        end
      end

      context 'when responses are objects' do
        let(:framework_response) { create(:object_response, :details, person_escort_record: person_escort_record) }
        let(:other_framework_response) { create(:object_response, :details, person_escort_record: person_escort_record) }
        let(:value) { { option: 'No', details: 'Some details' } }
        let(:other_value) { { option: 'Yes', details: nil } }

        it 'updates response values' do
          expect(framework_response.reload.value).to eq(value.stringify_keys)
          expect(other_framework_response.reload.value).to eq(other_value.stringify_keys)
        end
      end

      context 'when responses are details collection' do
        let(:framework_response) { create(:collection_response, :details, person_escort_record: person_escort_record) }
        let(:other_framework_response) { create(:collection_response, :details, person_escort_record: person_escort_record) }
        let(:value) { [{ option: 'Level 1', details: 'Some details' }, { option: 'Level 2', details: nil }] }
        let(:other_value) { [{ option: 'Level 1', details: nil }, { option: 'Level 2', details: 'Some details' }] }

        it 'updates response values' do
          expect(framework_response.reload.value).to eq(value.map(&:stringify_keys))
          expect(other_framework_response.reload.value).to eq(other_value.map(&:stringify_keys))
        end
      end

      context 'when responses are multiple item collection' do
        let(:framework_response) { create(:collection_response, :multiple_items, framework_question: question, value: nil, person_escort_record: person_escort_record) }
        let(:other_framework_response) { create(:collection_response, :multiple_items, framework_question: question, value: nil, person_escort_record: person_escort_record) }
        let(:question1) { create(:framework_question) }
        let(:question2) { create(:framework_question, :checkbox) }
        let(:question3) { create(:framework_question, :checkbox, followup_comment: true) }
        let(:question4) { create(:framework_question, followup_comment: true) }
        let(:question) { create(:framework_question, :add_multiple_items, dependents: [question1, question2, question3, question4]) }
        let(:value) do
          [
            { item: 1, responses: [{ value: 'No', framework_question_id: question1.id }] },
            { item: 2, responses: [{ value: ['Level 2'], framework_question_id: question2.id }] },
            { item: 3, responses: [{ value: [{ option: 'Level 1', details: 'some detail' }], framework_question_id: question3.id }] },
            { item: 4, responses: [{ value: { option: 'No', details: 'some detail' }, framework_question_id: question4.id }] },
          ]
        end
        let(:other_value) do
          [
            { item: 1, responses: [{ value: 'Yes', framework_question_id: question1.id }] },
            { item: 2, responses: [{ value: ['Level 2'], framework_question_id: question2.id }] },
            { item: 3, responses: [{ value: [{ option: 'Level 1', details: nil }], framework_question_id: question3.id }] },
            { item: 4, responses: [{ value: { option: 'Yes', details: nil }, framework_question_id: question4.id }] },
          ]
        end

        it 'updates response values' do
          expect(framework_response.reload.value).to eq(value.map(&:deep_stringify_keys))
          expect(other_framework_response.reload.value).to eq(other_value.map(&:deep_stringify_keys))
        end
      end

      context 'when incorrect keys added to details collection responses' do
        let(:framework_response) { create(:collection_response, :details, person_escort_record: person_escort_record) }
        let(:other_framework_response) { create(:collection_response, :details, person_escort_record: person_escort_record) }
        let(:value) { [{ option: 'Level 1', detailss: 'Some details' }] }
        let(:other_value) { [{ option: 'Level 1', detailzz: 'Some details' }] }

        it 'updates response values' do
          expect(framework_response.reload.value).to eq([{ 'option' => 'Level 1', 'details' => nil }])
          expect(other_framework_response.reload.value).to eq([{ 'option' => 'Level 1', 'details' => nil }])
        end
      end

      context 'when incorrect keys added to multiple items collection responses' do
        let(:framework_response) { create(:collection_response, :multiple_items, person_escort_record: person_escort_record) }
        let(:other_framework_response) { create(:collection_response, :multiple_items, person_escort_record: person_escort_record) }
        let(:framework_question) { framework_response.framework_question.dependents.first }
        let(:other_framework_question) { other_framework_response.framework_question.dependents.first }

        let(:value) do
          [
            { items: 1, responses: [{ value: ['Level 1'], framework_question_id: framework_question.id }] },
            { item: 2, responses: [{ value: ['Level 2'], framework_question_id: framework_question.id }] },
          ]
        end
        let(:other_value) do
          [
            { items: 1, responses: [{ value: ['Level 1'], framework_question_id: other_framework_question.id }] },
            { item: 2, responses: [{ value: ['Level 2'], framework_question_id: other_framework_question.id }] },
          ]
        end

        it 'updates response values' do
          expect(framework_response.reload.value).to eq([{ 'item' => 2, 'responses' => [{ 'value' => ['Level 2'], 'framework_question_id' => framework_question.id }] }])
          expect(other_framework_response.reload.value).to eq([{ 'item' => 2, 'responses' => [{ 'value' => ['Level 2'], 'framework_question_id' => other_framework_question.id }] }])
        end
      end

      context 'when incorrect keys added to object responses' do
        let(:framework_response) { create(:object_response, :details, person_escort_record: person_escort_record) }
        let(:other_framework_response) { create(:object_response, :details, person_escort_record: person_escort_record) }
        let(:value) { { option: 'Yes', detailss: 'Some details' } }
        let(:other_value) { { option: 'No', detailzz: 'Some details' } }

        it 'updates response values' do
          expect(framework_response.reload.value).to eq({ 'option' => 'Yes', 'details' => nil })
          expect(other_framework_response.reload.value).to eq({ 'option' => 'No', 'details' => nil })
        end
      end
    end

    context 'when unsuccessful' do
      before { bulk_update_framework_responses }

      context 'with a bad request' do
        let(:bulk_per_params) { nil }

        it_behaves_like 'an endpoint that responds with error 400'
      end

      context 'when the person_escort_record_id is not found' do
        let(:per_id) { 'foo-bar' }
        let(:detail_404) { "Couldn't find PersonEscortRecord with 'id'=foo-bar" }

        it_behaves_like 'an endpoint that responds with error 404'
      end

      context 'with invalid values' do
        let(:value) { 'foo-bar' }
        let(:other_value) { 'bar-baz' }

        it_behaves_like 'an endpoint that responds with error 422' do
          let(:errors_422) do
            [
              {
                'id' => framework_response_id,
                'title' => 'Invalid value',
                'detail' => 'Value is not included in the list',
              },
              {
                'id' => other_framework_response_id,
                'title' => 'Invalid value',
                'detail' => 'Value is not included in the list',
              },
            ]
          end
        end
      end

      context 'with incorrect value type' do
        let(:value) { %w[foo-bar] }
        let(:other_value) { %w[bar-baz] }

        it_behaves_like 'an endpoint that responds with error 422' do
          let(:errors_422) do
            [
              {
                'id' => framework_response_id,
                'title' => 'Invalid value',
                'detail' => 'Value: ["foo-bar"] is incorrect type',
                'source' => { pointer: '/data/attributes/value' },
              },
              {
                'id' => other_framework_response_id,
                'title' => 'Invalid value',
                'detail' => 'Value: ["bar-baz"] is incorrect type',
                'source' => { pointer: '/data/attributes/value' },
              },
            ]
          end
        end
      end

      context 'with a nested invalid value' do
        let(:framework_response) { create(:collection_response, :multiple_items, person_escort_record: person_escort_record) }
        let(:framework_question) { framework_response.framework_question.dependents.first }
        let(:other_framework_response) { create(:collection_response, :multiple_items, person_escort_record: person_escort_record) }
        let(:other_framework_question) { other_framework_response.framework_question.dependents.first }

        let(:value) do
          [
            { item: 1, responses: [{ value: ['Level 1'], framework_question_id: framework_question.id }] },
            { item: 2, responses: [{ value: ['Level 3'], framework_question_id: framework_question.id }] },
            { item: 3, responses: [{ value: ['Level 2'], framework_question_id: framework_question.id }] },
          ]
        end
        let(:other_value) do
          [
            { item: 1, responses: [{ value: ['Level 1'], framework_question_id: other_framework_question.id }] },
            { item: 2, responses: [{ value: ['Level 3'], framework_question_id: other_framework_question.id }] },
            { item: 3, responses: [{ value: ['Level 2'], framework_question_id: other_framework_question.id }] },
          ]
        end

        it_behaves_like 'an endpoint that responds with error 422' do
          let(:errors_422) do
            [
              {
                'id' => framework_response_id,
                'title' => 'Invalid value',
                'detail' => 'Items[1] responses[0] value Level 3 are not valid options',
              },
              {
                'id' => other_framework_response_id,
                'title' => 'Invalid value',
                'detail' => 'Items[1] responses[0] value Level 3 are not valid options',
              },
            ]
          end
        end
      end

      context 'with a nested incorrect value type' do
        let(:framework_response) { create(:collection_response, :multiple_items, person_escort_record: person_escort_record) }
        let(:framework_question) { framework_response.framework_question.dependents.first }
        let(:other_framework_response) { create(:collection_response, :multiple_items, person_escort_record: person_escort_record) }
        let(:other_framework_question) { other_framework_response.framework_question.dependents.first }

        let(:value) do
          [
            { item: 1, responses: [{ value: ['Level 1'], framework_question_id: framework_question.id }] },
            { item: 2, responses: [{ value: 'Level 2', framework_question_id: framework_question.id }] },
            { item: 3, responses: [{ value: ['Level 2'], framework_question_id: framework_question.id }] },
          ]
        end
        let(:other_value) do
          [
            { item: 1, responses: [{ value: ['Level 1'], framework_question_id: other_framework_question.id }] },
            { item: 2, responses: [{ value: 'Level 2', framework_question_id: other_framework_question.id }] },
            { item: 3, responses: [{ value: ['Level 2'], framework_question_id: other_framework_question.id }] },
          ]
        end

        it_behaves_like 'an endpoint that responds with error 422' do
          let(:errors_422) do
            [
              {
                'id' => framework_response_id,
                'title' => 'Invalid value',
                'detail' => 'Value: Level 2 is incorrect type',
                'source' => { pointer: '/data/attributes/value' },
              },
              {
                'id' => other_framework_response_id,
                'title' => 'Invalid value',
                'detail' => 'Value: Level 2 is incorrect type',
                'source' => { pointer: '/data/attributes/value' },
              },
            ]
          end
        end
      end

      context 'when person_escort_record confirmed' do
        let(:person_escort_record) { create(:person_escort_record, :confirmed) }
        let(:detail_403) { "Can't update framework_responses because person_escort_record is confirmed" }

        it_behaves_like 'an endpoint that responds with error 403'
      end

      context 'when the framework_response_id is not found' do
        let(:framework_response_id) { 'foo' }
        let(:other_framework_response_id) { 'bar' }
        let(:detail_404) { "Couldn't find FrameworkResponse with 'id'=[\"foo\", \"bar\"]" }

        it_behaves_like 'an endpoint that responds with error 404'
      end
    end
  end
end
