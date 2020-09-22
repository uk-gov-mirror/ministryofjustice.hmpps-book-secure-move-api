RSpec.describe GenericEvent::JourneyUncomplete do
  subject(:generic_event) { build(:event_journey_uncomplete) }

  it_behaves_like 'a journey event', :uncomplete do
    subject(:generic_event) { build(:event_journey_uncomplete) }
  end

  describe '.from_event' do
    let(:journey) { create(:journey) }
    let(:event) { create(:event, :uncomplete, eventable: journey) }

    let(:expected_generic_event_attributes) do
      {
        'id' => nil,
        'eventable_id' => journey.id,
        'eventable_type' => 'Journey',
        'type' => 'GenericEvent::JourneyUncomplete',
        'notes' => 'foo',
        'created_by' => 'unknown',
        'details' => {},
        'occurred_at' => eq(event.client_timestamp),
        'recorded_at' => eq(event.client_timestamp),
        'created_at' => be_within(0.1.seconds).of(event.created_at),
        'updated_at' => be_within(0.1.seconds).of(event.updated_at),
      }
    end

    it 'builds a generic_event with the correct attributes' do
      expect(described_class.from_event(event).attributes).to include_json(expected_generic_event_attributes)
    end

    it 'builds a valid generic_event' do
      expect(described_class.from_event(event)).to be_valid
    end
  end
end