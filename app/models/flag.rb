# frozen_string_literal: true

class Flag < VersionedModel
  enum flag_type: {
    information: 'information',
    attention: 'attention',
    warning: 'warning',
    alert: 'alert',
  }

  validates :flag_type, presence: true, inclusion: { in: flag_types }
  validates :name, presence: true
  validates :question_value, presence: true

  belongs_to :framework_question
end