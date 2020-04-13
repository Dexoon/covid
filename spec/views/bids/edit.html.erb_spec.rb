require 'rails_helper'

RSpec.describe "bids/edit", type: :view do
  before(:each) do
    @bid = assign(:bid, Bid.create!(
      region: nil,
      contact_info: "MyText",
      aasm_state: "MyString"
    ))
  end

  it "renders the edit bid form" do
    render

    assert_select "form[action=?][method=?]", bid_path(@bid), "post" do

      assert_select "input[name=?]", "bid[region_id]"

      assert_select "textarea[name=?]", "bid[contact_info]"

      assert_select "input[name=?]", "bid[aasm_state]"
    end
  end
end
