class Knock < ApplicationRecord
  belongs_to :door
  belongs_to :canvasser
  has_many :answers
end
