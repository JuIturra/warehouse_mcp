class Slot < ApplicationRecord
  belongs_to :yard
  has_one :container

  validates :row, :column, presence: true
  validates :row, uniqueness: { scope: [:column, :yard_id] }

  def occupied?
    container.present?
  end
end
