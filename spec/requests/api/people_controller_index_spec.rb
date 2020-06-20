# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PeopleController do
  let!(:token) { create(:access_token) }
  let(:response_json) { JSON.parse(response.body) }

  let(:schema) { load_yaml_schema('get_people_responses.yaml') }

  describe 'GET /v1/people' do
    let(:prison_number) { 'G5033UT' }
    let(:params) { { filter: { police_national_computer: 'AB/1234567' }, access_token: token.token } }

    context 'when called with police_national_computer filter' do
      let!(:people) { create_list :person, 5, :nomis_synced, police_national_computer: 'AB/1234567' }

      before do
        get '/api/v1/people', headers: headers, params: params
      end

      it_behaves_like 'an endpoint that responds with success 200'

      it 'returns the correct data' do
        expect(response_json['data'].size).to eq(5)
      end
    end

    context 'with no ethnicity' do
      let!(:person) { create(:person, ethnicity: nil) }

      before do
        get '/api/v1/people', headers: headers, params: params
      end

      it_behaves_like 'an endpoint that responds with success 200'
    end

    it 'delegates the query execution to People::Finder with correct filter', skip_before: true do
      people_finder = instance_double('People::Finder', call: Person.all)
      allow(People::Finder).to receive(:new).and_return(people_finder)

      get '/api/v1/people', headers: headers, params: params

      expect(People::Finder).to have_received(:new).with(police_national_computer: 'AB/1234567')
    end

    context 'when the filter prison_number is used' do
      let!(:people) { create_list :person, 5, gender: gender, ethnicity: ethnicity }
      let(:gender) { create(:gender) }
      let(:ethnicity) { create(:ethnicity) }

      let(:params) { { filter: { prison_number: prison_number }, access_token: token.token } }
      let(:people_finder) { instance_double('People::Finder', call: Person.all) }

      before do
        allow(People::Finder).to receive(:new).and_return(people_finder)
        allow(Moves::ImportPeople).to receive(:new).with([prison_number])
          .and_return(instance_double('Moves::ImportPeople', call: nil))
        get '/api/v1/people', headers: headers, params: params
      end

      it 'requests data from NOMIS' do
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'included relationships', :skip_before do
      let!(:people) { create_list :person, 2, police_national_computer: 'AB/1234567' }

      before do
        get "/api/v1/people#{query_params}", headers: headers, params: params
      end

      context 'when not including the include query param' do
        let(:query_params) { '' }

        it 'returns the default includes' do
          returned_types = response_json['included'].map { |r| r['type'] }.uniq
          expect(returned_types).to contain_exactly('ethnicities', 'genders')
        end
      end

      context 'when including the include query param' do
        let(:query_params) { '?include=gender' }

        it 'returns the valid provided includes' do
          returned_types = response_json['included'].map { |r| r['type'] }.uniq
          expect(returned_types).to contain_exactly('genders')
        end
      end

      context 'when including an invalid include query param' do
        let(:query_params) { '?include=foo.bar,gender' }

        let(:expected_error) do
          {
            'errors' => [
              {
                'title' => 'Bad request',
                'detail' => '["foo.bar"] is not supported. Valid values are: ["ethnicity", "gender"]',
              },
            ],
          }
        end

        it 'returns a validation error' do
          expect(response).to have_http_status(:bad_request)
          expect(response_json).to eq(expected_error)
        end
      end

      context 'when including an empty include query param' do
        let(:query_params) { '?include=' }

        it 'returns none of the includes' do
          returned_types = response_json['included']
          expect(returned_types).to be_nil
        end
      end

      context 'when including a nil include query param' do
        let(:query_params) { '?include' }

        it 'returns the default includes' do
          returned_types = response_json['included'].map { |r| r['type'] }.uniq

          expect(returned_types).to contain_exactly('ethnicities', 'genders')
        end
      end
    end
  end
end