require 'rails_helper'

RSpec.describe "bids/show", type: :view do
  before(:each) do
    @bid = assign(:bid, Bid.create!(
      region: nil,
      contact_info: "MyText",
      aasm_state: "Aasm State"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Aasm State/)
  end
end
