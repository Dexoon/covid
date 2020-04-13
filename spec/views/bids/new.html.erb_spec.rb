require 'rails_helper'

RSpec.describe "bids/new", type: :view do
  before(:each) do
    assign(:bid, Bid.new(
      region: nil,
      contact_info: "MyText",
      aasm_state: "MyString"
    ))
  end

  it "renders new bid form" do
    render

    assert_select "form[action=?][method=?]", bids_path, "post" do

      assert_select "input[name=?]", "bid[region_id]"

      assert_select "textarea[name=?]", "bid[contact_info]"

      assert_select "input[name=?]", "bid[aasm_state]"
    end
  end
end
