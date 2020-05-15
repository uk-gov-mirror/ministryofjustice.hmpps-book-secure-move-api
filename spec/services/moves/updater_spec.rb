# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Moves::Updater do
  subject(:updater) { described_class.new(move, move_params) }

  let(:before_documents) { create_list(:document, 2) }
  let!(:from_location) { create :location }
  let!(:move) { create :move, :proposed, move_type: 'prison_recall', from_location: from_location, documents: before_documents }
  let(:date_from) { Date.yesterday }
  let(:date_to) { Date.tomorrow }
  let(:status) { 'requested' }

  let(:move_params) do
    {
      type: 'moves',
      attributes: {
        status: status,
        additional_information: 'some more info',
        cancellation_reason: nil,
        cancellation_reason_comment: nil,
        move_type: 'court_appearance',
        move_agreed: true,
        move_agreed_by: 'Fred Bloggs',
        date_from: date_from,
        date_to: date_to,
      },
    }
  end

  before do
    next if RSpec.current_example.metadata[:skip_before]

    updater.call
  end

  context 'with valid params' do
    it 'updates the correct attributes on an existing move' do
      expect(updater.move).to have_attributes(
        status: 'requested',
        additional_information: 'some more info',
        move_type: 'court_appearance',
        move_agreed: true,
        move_agreed_by: 'Fred Bloggs',
        date_from: date_from,
        date_to: date_to,
      )
    end

    context 'when status updated' do
      it 'sets `status_updated` to `true`' do
        expect(updater.status_changed).to be_truthy
      end
    end

    context 'when status is not updated' do
      let(:status) { 'proposed' }

      it 'sets `status_updated` to `false`' do
        expect(updater.status_changed).to be_falsey
      end
    end

    context 'with people' do
      let(:before_person) { create(:person) }
      let(:after_person) { create(:person) }
      let!(:move) { create(:move, person: before_person) }

      context 'with new person' do
        let(:move_params) {
          {
            type: 'moves',
            relationships: { person: { data: { id: after_person.id, type: 'people' } } },
          }
        }

        it 'updates person association to new person' do
          expect(updater.move.person).to eq(after_person)
        end
      end

      context 'with empty person data' do
        let(:move_params) {
          {
            type: 'moves',
            relationships: { person: { data: nil } },
          }
        }

        it 'removes associated person' do
          expect(updater.move.person).to be_nil
        end
      end

      context 'with no person relationship' do
        it 'does not change old person associated' do
          expect(updater.move.person).to eq(before_person)
        end
      end
    end

    context 'with documents' do
      context 'with new documents' do
        let(:after_documents) { create_list(:document, 2) }
        let(:move_params) do
          documents = after_documents.map { |d| { id: d.id, type: 'documents' } }
          {
            type: 'moves',
            relationships: { documents: { data: documents } },
          }
        end

        it 'updates documents association to new documents' do
          expect(updater.move.documents).to match_array(after_documents)
        end
      end

      context 'with empty documents' do
        let(:move_params) {
          {
            type: 'moves',
            relationships: { documents: { data: [] } },
          }
        }

        it 'unsets associated documents' do
          expect(updater.move.documents).to be_empty
        end
      end

      context 'with nil documents' do
        let(:move_params) {
          {
            type: 'moves',
            relationships: { documents: { data: nil } },
          }
        }

        it 'does nothing to existing documents' do
          expect(updater.move.documents).to match_array(before_documents)
        end
      end

      context 'with no document relationship' do
        it 'does nothing to existing documents' do
          expect(updater.move.documents).to match_array(before_documents)
        end
      end
    end
  end

  context 'with invalid input params' do
    let(:status) { 'wrong status' }

    it 'raises an error', :skip_before do
      expect { updater.call }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end