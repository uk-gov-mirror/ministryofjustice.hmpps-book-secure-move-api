# frozen_string_literal: true

class Profile < ApplicationRecord
  before_validation :set_assessment_answers

  belongs_to :person
  belongs_to :ethnicity, optional: true
  belongs_to :gender, optional: true
  has_many :moves, dependent: :destroy

  validates :person, presence: true
  validates :last_name, presence: true
  validates :first_names, presence: true
  validate :validate_assessment_answers

  attribute :assessment_answers, Profile::AssessmentAnswers::Type.new
  attribute :profile_identifiers, Profile::ProfileIdentifiers::Type.new

  IDENTIFIER_TYPES = %w[
    police_national_computer criminal_records_office prison_number niche_reference athena_reference
  ].freeze

  def merge_assessment_answers!(new_assessment_answers, category)
    self.assessment_answers =
      assessment_answers.reject { |a| a.category == category } +
      manually_created_assessment_answers.select { |a| a.category == category } +
      new_assessment_answers
  end

private

  def manually_created_assessment_answers
    assessment_answers.reject(&:imported_from_nomis)
  end

  def set_assessment_answers
    assessment_answers.each(&:set_timestamps)
    assessment_answers.each(&:copy_question_attributes)
  end

  def validate_assessment_answers
    return if assessment_answers.all?(&:valid?)

    errors.add(:assessment_answers, 'One or more assessment answers is invalid')
  end
end
