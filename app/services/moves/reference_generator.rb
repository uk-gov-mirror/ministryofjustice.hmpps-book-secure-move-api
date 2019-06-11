# frozen_string_literal: true

module Moves
  class ReferenceGenerator
    def call
      loop do
        reference = PERMISSIBLE_CHARACTERS.sample(REFERENCE_LENGTH).join
        break reference unless Move.where(reference: reference).exists?
      end
    end

    REFERENCE_LENGTH = 8
    PERMISSIBLE_CHARACTERS = %i[A C E F H J K M N P R T U V W X Y 1 2 3 4 5 6 7 8 9].freeze
  end
end