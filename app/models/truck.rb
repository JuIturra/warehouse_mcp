class Truck < ApplicationRecord
  has_many :containers

  validates :plate, presence: true, uniqueness: true
end
