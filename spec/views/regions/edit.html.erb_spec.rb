require 'rails_helper'

RSpec.describe "regions/edit", type: :view do
  before(:each) do
    @region = assign(:region, Region.create!(
      name: "MyString",
      code: 1,
      chat_id: 1
    ))
  end

  it "renders the edit region form" do
    render

    assert_select "form[action=?][method=?]", region_path(@region), "post" do

      assert_select "input[name=?]", "region[name]"

      assert_select "input[name=?]", "region[code]"

      assert_select "input[name=?]", "region[chat_id]"
    end
  end
end
