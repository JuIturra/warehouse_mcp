require "test_helper"

class YardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @yard = yards(:one)
  end

  test "should get index" do
    get yards_url
    assert_response :success
  end

  test "should get new" do
    get new_yard_url
    assert_response :success
  end

  test "should create yard" do
    assert_difference("Yard.count") do
      post yards_url, params: { yard: { columns: @yard.columns, name: @yard.name, rows: @yard.rows } }
    end

    assert_redirected_to yard_url(Yard.last)
  end

  test "should show yard" do
    get yard_url(@yard)
    assert_response :success
  end

  test "should get edit" do
    get edit_yard_url(@yard)
    assert_response :success
  end

  test "should update yard" do
    patch yard_url(@yard), params: { yard: { columns: @yard.columns, name: @yard.name, rows: @yard.rows } }
    assert_redirected_to yard_url(@yard)
  end

  test "should destroy yard" do
    assert_difference("Yard.count", -1) do
      delete yard_url(@yard)
    end

    assert_redirected_to yards_url
  end

  test "process_arrival reuses existing truck plate" do
    yard = Yard.create!(name: "Process Yard", rows: 1, columns: 2)

    assert_difference("Truck.count", 1) do
      assert_difference("Container.count", 1) do
        post process_arrival_yard_url(yard), params: {
          plate: "KMLP56",
          containers: "CXX45"
        }
      end
    end

    assert_redirected_to yard_url(yard)

    assert_no_difference("Truck.count") do
      assert_difference("Container.count", 1) do
        post process_arrival_yard_url(yard), params: {
          plate: "KMLP56",
          containers: "CPP12"
        }
      end
    end

    assert_redirected_to yard_url(yard)
  end

  test "process_arrival does not crash when container code already exists" do
    yard = Yard.create!(name: "Duplicate Code Yard", rows: 1, columns: 2)

    post process_arrival_yard_url(yard), params: {
      plate: "KMLP57",
      containers: "CXX45"
    }
    assert_redirected_to yard_url(yard)

    assert_no_difference("Container.count") do
      post process_arrival_yard_url(yard), params: {
        plate: "KMLP57",
        containers: "CXX45"
      }
    end

    assert_redirected_to yard_url(yard)
  end
end
