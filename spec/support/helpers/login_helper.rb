module LoginHelper
  def login_with(email, password, action)
    visit login_path
    fill_in "email", with: email
    fill_in "password", with: password
    page.find("input[name=commit]").click
  end

  def register(email, password, password_confirmation, action)
    visit new_user_path
    fill_in "user[email]", with: email
    fill_in "user[password]", with: password
    fill_in "user[password_confirmation]", with: password_confirmation
    click_button action
  end
end
