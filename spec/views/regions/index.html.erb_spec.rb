require 'rails_helper'

RSpec.describe "regions/index", type: :view do
  before(:each) do
    assign(:regions, [
      Region.create!(
        name: "Name",
        code: 2,
        chat_id: 3
      ),
      Region.create!(
        name: "Name",
        code: 2,
        chat_id: 3
      )
    ])
  end

  it "renders a list of regions" do
    render
    assert_select "tr>td", text: "Name".to_s, count: 2
    assert_select "tr>td", text: 2.to_s, count: 2
    assert_select "tr>td", text: 3.to_s, count: 2
  end
end
