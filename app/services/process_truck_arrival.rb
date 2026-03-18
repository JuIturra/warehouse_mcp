# app/services/process_truck_arrival.rb
class ProcessTruckArrival
  def initialize(yard:, truck:, container_codes:)
    @yard = yard
    @truck = truck
    @container_codes = container_codes
  end

  def call
    results = []

    @container_codes.each do |code|
      if Container.exists?(code: code)
        results << { code: code, status: :failed, reason: "Container code already exists" }
        next
      end

      slot = @yard.next_free_slot

      if slot.nil?
        results << { code: code, status: :failed, reason: "No space available" }
        next
      end

      Container.create!(
        code: code,
        truck: @truck,
        slot: slot
      )

      results << { code: code, status: :stored, slot: [slot.row, slot.column] }
    rescue ActiveRecord::RecordInvalid => e
      results << { code: code, status: :failed, reason: e.record.errors.full_messages.to_sentence }
    end

    results
  end
end
