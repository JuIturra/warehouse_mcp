class YardsController < ApplicationController
  before_action :set_yard, only: %i[edit update destroy ]

  # GET /yards or /yards.json
  def index
    @yards = Yard.includes(slots: :container)
  end

  # GET /yards/1 or /yards/1.json
  def show
    @yard = Yard.includes(slots: :container).find(params[:id])
    @slots_map = @yard.slots.index_by { |s| [s.row, s.column] }
  end

  # GET /yards/new
  def new
    @yard = Yard.new
  end

  # GET /yards/1/edit
  def edit
  end

  # POST /yards or /yards.json
  def create
    @yard = Yard.new(yard_params)

    respond_to do |format|
      if @yard.save
        format.html { redirect_to @yard, notice: "Yard was successfully created." }
        format.json { render :show, status: :created, location: @yard }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @yard.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /yards/1 or /yards/1.json
  def update
    respond_to do |format|
      if @yard.update(yard_params)
        format.html { redirect_to @yard, notice: "Yard was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @yard }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @yard.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /yards/1 or /yards/1.json
  def destroy
    @yard.destroy!

    respond_to do |format|
      format.html { redirect_to yards_path, notice: "Yard was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def process_arrival
    @yard = Yard.find(params[:id])

    plate = params[:plate].to_s.strip
    container_codes = params[:containers].to_s.split(",").map(&:strip).reject(&:blank?)

    if plate.blank? || container_codes.empty?
      redirect_to @yard, alert: "Debe ingresar patente y al menos un contenedor"
      return
    end

    truck = Truck.find_or_create_by!(plate: plate)

    service = ProcessTruckArrival.new(
      yard: @yard,
      truck: truck,
      container_codes: container_codes
    )

    results = service.call

    redirect_to @yard, notice: results.map { |r|
      if r[:status] == :stored
        "#{r[:code]} → (#{r[:slot].join(",")})"
      else
        "#{r[:code]} → ERROR: #{r[:reason]}"
      end
    }.join(" | ")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @yard, alert: e.record.errors.full_messages.to_sentence
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_yard
      @yard = Yard.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def yard_params
      params.require(:yard).permit(:name, :rows, :columns)
    end
end
