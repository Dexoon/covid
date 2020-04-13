require 'rails_helper'

RSpec.describe "users/edit", type: :view do
  before(:each) do
    @user = assign(:user, User.create!(
      type: "",
      name: "MyString",
      username: "MyString",
      tg_id: 1
    ))
  end

  it "renders the edit user form" do
    render

    assert_select "form[action=?][method=?]", user_path(@user), "post" do

      assert_select "input[name=?]", "user[type]"

      assert_select "input[name=?]", "user[name]"

      assert_select "input[name=?]", "user[username]"

      assert_select "input[name=?]", "user[tg_id]"
    end
  end
end
