require 'rails_helper'

RSpec.describe "bids/index", type: :view do
  before(:each) do
    assign(:bids, [
      Bid.create!(
        region: nil,
        contact_info: "MyText",
        aasm_state: "Aasm State"
      ),
      Bid.create!(
        region: nil,
        contact_info: "MyText",
        aasm_state: "Aasm State"
      )
    ])
  end

  it "renders a list of bids" do
    render
    assert_select "tr>td", text: nil.to_s, count: 2
    assert_select "tr>td", text: "MyText".to_s, count: 2
    assert_select "tr>td", text: "Aasm State".to_s, count: 2
  end
end
