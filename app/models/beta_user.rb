class BetaUser < ApplicationRecord
  validates :email, presence: true
end
