# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::MovesController do
  let(:token) { create(:access_token) }
  let(:headers) { { 'CONTENT_TYPE': content_type, 'Authorization' => "Bearer #{token.token}" } }
  let(:content_type) { ApiController::CONTENT_TYPE }
  let(:response_json) { JSON.parse(response.body) }

  describe 'GET /moves' do
    let!(:move1) { create :move }
    let!(:move2) { create :move, :with_transfer_reason }
    let!(:move3) { create :move, :with_transfer_reason }
    let!(:move4) { create :move }

    before do
      next if RSpec.current_example.metadata[:skip_before]

      get '/api/v1/moves', headers: headers, params: { sort: sort_params }
    end

    describe 'sorting' do
      describe 'errors' do
        context 'with invalid sort' do
          let(:sort_params) { { by: 'rabbits' } }

          it 'produces an error' do
            expect(response).to have_http_status(:bad_request)
            expect(JSON.parse(response.body)).to eq('error' => { 'sort_by' => ['is not included in the list'] })
          end
        end

        context 'with invalid direction' do
          let(:sort_params) { { by: 'created_at', direction: 'rabbits' } }

          it 'produces an error' do
            expect(response).to have_http_status(:bad_request)
            expect(JSON.parse(response.body)).to eq('error' => { 'sort_direction' => ['is not included in the list'] })
          end
        end

        context 'with only direction' do
          let(:sort_params) { { direction: 'asc' } }

          it 'produces an error' do
            expect(response).to have_http_status(:bad_request)
            expect(JSON.parse(response.body)).to eq('error' => { 'sort_by' => ["can't be blank"] })
          end
        end
      end

      context 'with attributes' do
        let(:move_ids) { response_json['data'].map { |move| move.fetch('id') } }

        context 'without explicit sort' do
          let(:expected) { Move.all.sort_by(&:date).reverse }

          it 'sorts by move date descending', :skip_before do
            get '/api/v1/moves', headers: headers

            expect(move_ids).to eq(expected.map(&:id))
          end
        end

        context 'when created_at' do
          context 'when default' do
            let(:sort_params) { { by: 'created_at' } }
            let(:expected) { Move.all.sort_by(&:created_at) }

            it 'sorts by created_at' do
              expect(move_ids).to eq(expected.map(&:id))
            end
          end

          context 'when reversed' do
            let(:sort_params) { { by: 'created_at', direction: 'desc' } }
            let(:expected) { Move.all.sort_by(&:created_at).reverse }

            it 'sorts by created_at' do
              expect(move_ids).to eq(expected.map(&:id))
            end
          end
        end

        context 'when date' do
          let(:move_data) { Move.all.sort_by(&:date) }

          context 'when default' do
            let(:sort_params) { { by: 'date' } }

            it 'sorts by date' do
              expect(move_ids).to eq(move_data.map(&:id))
            end
          end

          context 'when reversed' do
            let(:sort_params) { { by: 'date', direction: 'desc' } }

            it 'sorts by date' do
              expect(move_ids).to eq(move_data.reverse.map(&:id))
            end
          end
        end

        context 'when date_from' do
          let(:move_data) { Move.all.sort_by(&:date_from) }

          context 'when default' do
            let(:sort_params) { { by: 'date_from' } }

            it 'sorts by date_from' do
              expect(move_ids).to eq(move_data.map(&:id))
            end
          end

          context 'when reversed' do
            let(:sort_params) { { by: 'date_from', direction: 'desc' } }

            it 'sorts by date_from' do
              expect(move_ids).to eq(move_data.reverse.map(&:id))
            end
          end
        end
      end

      context 'with nested objects' do
        let(:object_ids) { response_json['data'].map { |move| move.dig('relationships', object_name, 'data', 'id') } }

        context 'when from_location' do
          let(:object_name) { 'from_location' }
          let(:locations) { object_ids.map { |p_id| Location.find(p_id) } }

          context 'with default direction' do
            let(:sort_params) { { by: 'from_location' } }
            let(:expected) do
              Move.all.sort_by { |move| move.from_location.title }.map(&:from_location)
            end

            it 'sorts by from location' do
              expect(locations.map(&:title)).to eq(expected.map(&:title))
            end
          end

          context 'with reverse direction' do
            let(:sort_params) { { by: 'from_location', direction: 'desc' } }
            let(:expected) do
              Move.all.sort_by { |move| move.from_location.title }.reverse.map(&:from_location)
            end

            it 'sorts by from location' do
              expect(locations.map(&:title)).to eq(expected.map(&:title))
            end
          end
        end

        context 'when to_location' do
          let(:locations) { object_ids.map { |p_id| Location.find(p_id) } }
          let(:object_name) { 'to_location' }
          let(:move_data) { Move.all.sort_by { |move| move.to_location.title }.map(&:to_location) }

          context 'with default direction' do
            let(:sort_params) { { by: 'to_location' } }

            it 'sorts by to location' do
              expect(locations.map(&:title)).to eq(move_data.map(&:title))
            end
          end

          context 'with reverse direction' do
            let(:sort_params) { { by: 'to_location', direction: 'desc' } }

            it 'sorts by to location' do
              expect(locations.map(&:title)).to eq(move_data.reverse.map(&:title))
            end
          end
        end

        context 'when name' do
          let(:people) { object_ids.map { |p_id| Person.find(p_id) } }
          let(:object_name) { 'person' }
          let(:move_data) { Move.all.sort_by { |move| move.person.latest_profile.last_name }.map(&:person) }

          context 'with default direction' do
            let(:sort_params) { { by: 'name' } }

            it 'sorts by to location' do
              expect(people).to eq(move_data)
            end
          end

          context 'with reverse direction' do
            let(:sort_params) { { by: 'name', direction: 'desc' } }

            it 'sorts by to location' do
              expect(people).to eq(move_data.reverse)
            end
          end
        end

        context 'with prison_transfer_reason' do
          let(:sort_params) { { by: 'prison_transfer_reason', direction: 'desc' } }
          let(:object_name) { 'prison_transfer_reason' }

          let(:reasons) { object_ids.map { |p_id| p_id.nil? ? '' : PrisonTransferReason.find(p_id).title } }
          let(:expected) do
            ['', ''] + [move2, move3].map { |move| move.prison_transfer_reason.title }.sort.reverse
          end

          it 'sorts by prison_transfer_reason' do
            expect(reasons).to eq(expected)
          end
        end
      end
    end
  end
end