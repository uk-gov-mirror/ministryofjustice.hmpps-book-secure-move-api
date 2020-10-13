# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PopulationsController do
  let(:access_token) { 'spoofed-token' }
  let(:headers) { { 'CONTENT_TYPE': content_type }.merge('Authorization' => "Bearer #{access_token}") }
  let(:response_json) { JSON.parse(response.body) }
  let(:content_type) { ApiController::CONTENT_TYPE }

  describe 'GET /locations_free_spaces' do
    subject(:get_locations_free_spaces) { get '/api/locations_free_spaces', params: params.merge(date_params), headers: headers }

    let(:schema) { load_yaml_schema('get_locations_responses.yaml') }
    let(:params) { {} }
    let(:date_from) { Date.today }
    let(:date_to) { Date.tomorrow }
    let(:date_params) { { date_from: date_from.to_s, date_to: date_to.to_s } }

    context 'when successful' do
      before { get_locations_free_spaces }

      it_behaves_like 'an endpoint that responds with success 200'
    end

    describe 'meta data' do
      let!(:location) { create(:location, :prison) }
      let!(:population) { create(:population, location: location, date: date_from) }
      let(:expected_json) do
        {
          data: [
            {
              "id": location.id,
              "type": 'locations',
              "attributes": {
                "title": location.title,
              },
              "meta": {
                "populations": [
                  {
                    "id": population.id,
                    "free_spaces": population.free_spaces,
                  },
                  nil,
                ],
              },
            },
          ],
        }
      end

      it 'includes population id and free spaces' do
        get_locations_free_spaces
        expect(response_json).to include_json(expected_json)
      end
    end

    describe 'finding results' do
      before do
        locations_finder = instance_double('Locations::Finder', call: Location.all)
        allow(Locations::Finder).to receive(:new).and_return(locations_finder)
      end

      context 'with filters' do
        let(:location) { create :location, :prison }
        let(:region) { create :region, locations: [location] }
        let(:filters) do
          {
            bar: 'bar',
            region_id: region.id,
            location_id: location.id,
            foo: 'foo',
          }
        end
        let(:params) { { filter: filters } }

        it 'delegates the query execution to Locations::Finder with the correct filters' do
          get_locations_free_spaces
          expect(Locations::Finder).to have_received(:new).with({ region_id: region.id, location_id: location.id }, {})
        end
      end

      context 'with sorting' do
        let(:sort) do
          {
            bar: 'bar',
            by: 'title',
            direction: 'desc',
            foo: 'foo',
          }
        end
        let(:params) { { sort: sort } }

        it 'delegates the query execution to Locations::Finder with the correct sorting' do
          get_locations_free_spaces
          expect(Locations::Finder).to have_received(:new).with({}, { by: 'title', direction: 'desc' })
        end
      end
    end

    describe 'paginating results' do
      let!(:locations) { create_list :location, 6 }
      let(:meta_pagination) do
        {
          per_page: 5,
          total_pages: 2,
          total_objects: 6,
        }
      end
      let(:pagination_links) do
        {
          self: "http://www.example.com/api/locations_free_spaces?date_from=#{date_from}&date_to=#{date_to}&page=1&per_page=5",
          first: "http://www.example.com/api/locations_free_spaces?date_from=#{date_from}&date_to=#{date_to}&page=1&per_page=5",
          prev: nil,
          next: "http://www.example.com/api/locations_free_spaces?date_from=#{date_from}&date_to=#{date_to}&page=2&per_page=5",
          last: "http://www.example.com/api/locations_free_spaces?date_from=#{date_from}&date_to=#{date_to}&page=2&per_page=5",
        }
      end

      before { get_locations_free_spaces }

      it_behaves_like 'an endpoint that paginates resources'
    end

    describe 'validating mandatory date parameters' do
      let(:date_params) { { date_from: date_from } }

      before { get_locations_free_spaces }

      it 'is a bad request' do
        expect(response.status).to eq(422)
      end

      it 'returns errors' do
        expect(response.body).to eq('{"errors":[{"title":"Invalid date_to","detail":"Validation failed: Date to can\'t be blank"}]}')
      end
    end

    describe 'validating dates before running queries' do
      let(:date_params) { { date_from: 'yyyy-09-Tu', date_to: date_to } }

      before { get_locations_free_spaces }

      it 'is a bad request' do
        expect(response.status).to eq(422)
      end

      it 'returns errors' do
        expect(response.body).to eq('{"errors":[{"title":"Invalid date_from","detail":"Validation failed: Date from is not a valid date"}]}')
      end
    end
  end
end
