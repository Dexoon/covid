require 'rails_helper'

RSpec.describe "users/index", type: :view do
  before(:each) do
    assign(:users, [
      User.create!(
        type: "Type",
        name: "Name",
        username: "Username",
        tg_id: 2
      ),
      User.create!(
        type: "Type",
        name: "Name",
        username: "Username",
        tg_id: 2
      )
    ])
  end

  it "renders a list of users" do
    render
    assert_select "tr>td", text: "Type".to_s, count: 2
    assert_select "tr>td", text: "Name".to_s, count: 2
    assert_select "tr>td", text: "Username".to_s, count: 2
    assert_select "tr>td", text: 2.to_s, count: 2
  end
end
