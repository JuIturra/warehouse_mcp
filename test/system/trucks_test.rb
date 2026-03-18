require "application_system_test_case"

class TrucksTest < ApplicationSystemTestCase
  setup do
    @truck = trucks(:one)
  end

  test "visiting the index" do
    visit trucks_url
    assert_selector "h1", text: "Trucks"
  end

  test "should create truck" do
    visit trucks_url
    click_on "New truck"

    fill_in "Plate", with: @truck.plate
    click_on "Create Truck"

    assert_text "Truck was successfully created"
    click_on "Back"
  end

  test "should update Truck" do
    visit truck_url(@truck)
    click_on "Edit this truck", match: :first

    fill_in "Plate", with: @truck.plate
    click_on "Update Truck"

    assert_text "Truck was successfully updated"
    click_on "Back"
  end

  test "should destroy Truck" do
    visit truck_url(@truck)
    click_on "Destroy this truck", match: :first

    assert_text "Truck was successfully destroyed"
  end
end
