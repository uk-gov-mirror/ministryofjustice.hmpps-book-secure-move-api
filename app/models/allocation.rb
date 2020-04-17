# frozen_string_literal: true

class Allocation < VersionedModel
  enum prisoner_category: {
    b: 'B',
    c: 'C',
    d: 'D',
  }

  enum sentence_length: {
    short: '16_or_less',
    long: 'more_than_16',
  }

  belongs_to :from_location, class_name: 'Location'
  belongs_to :to_location, class_name: 'Location'

  validates :from_location, presence: true
  validates :to_location, presence: true

  validates :prisoner_category, inclusion: { in: prisoner_categories }, allow_nil: true
  validates :sentence_length, inclusion: { in: sentence_lengths }, allow_nil: true

  validates :moves_count, presence: true
  validates :date, presence: true
end