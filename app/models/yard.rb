class Yard < ApplicationRecord
  has_many :slots, dependent: :destroy

  after_create :generate_slots

  validates :name, presence: true
  validates :rows, :columns, presence: true, numericality: { greater_than: 0 }

  def generate_slots
    (0...rows).each do |r|
      (0...columns).each do |c|
        slots.create!(row: r, column: c)
      end
    end
  end

  def next_free_slot
    slots
      .left_joins(:container)
      .where(containers: { id: nil })
      .lock("FOR UPDATE OF slots")
      .first
  end

  def total_slots
    rows * columns
  end

  def occupied_slots
    slots.joins(:container).count
  end

  def occupancy_percentage
    return 0 if total_slots.zero?

    ((occupied_slots.to_f / total_slots) * 100).round
  end
end
