# frozen_string_literal: true

class V2::ProfileSerializer
  include JSONAPI::Serializer
  include JSONAPI::ConditionalRelationships

  set_type :profiles

  attributes :assessment_answers

  belongs_to :person, serializer: ::V2::PersonSerializer
  has_many_if_included :documents, serializer: DocumentSerializer
  has_one_if_included :person_escort_record, serializer: PersonEscortRecordSerializer
  has_one_if_included :youth_risk_assessment, serializer: YouthRiskAssessmentSerializer

  SUPPORTED_RELATIONSHIPS = %w[documents person person_escort_record youth_risk_assessment].freeze
end
