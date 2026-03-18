class Container < ApplicationRecord
  belongs_to :slot, optional: true
  belongs_to :truck, optional: true

  validates :code, presence: true, uniqueness: true

  scope :stored, -> { where.not(slot_id: nil) }
  scope :in_transit, -> { where(slot_id: nil) }
end
