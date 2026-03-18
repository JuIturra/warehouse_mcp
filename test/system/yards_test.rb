require "application_system_test_case"

class YardsTest < ApplicationSystemTestCase
  setup do
    @yard = yards(:one)
  end

  test "visiting the index" do
    visit yards_url
    assert_selector "h1", text: "Yards"
  end

  test "should create yard" do
    visit yards_url
    click_on "New yard"

    fill_in "Columns", with: @yard.columns
    fill_in "Name", with: @yard.name
    fill_in "Rows", with: @yard.rows
    click_on "Create Yard"

    assert_text "Yard was successfully created"
    click_on "Back"
  end

  test "should update Yard" do
    visit yard_url(@yard)
    click_on "Edit this yard", match: :first

    fill_in "Columns", with: @yard.columns
    fill_in "Name", with: @yard.name
    fill_in "Rows", with: @yard.rows
    click_on "Update Yard"

    assert_text "Yard was successfully updated"
    click_on "Back"
  end

  test "should destroy Yard" do
    visit yard_url(@yard)
    click_on "Destroy this yard", match: :first

    assert_text "Yard was successfully destroyed"
  end
end
