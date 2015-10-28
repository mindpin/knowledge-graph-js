module UserLoginHelper
  def login_in(user)
    logout
    visit "/auth/login"
    within(".page-container") do
      fill_in "Email",    :with => user.email
      fill_in "密码",     :with => "1234"
    end
    click_button '提交'
    expect(page).to have_css ".desc.current-user"
  end

  def logout
    visit "/"
    first("a[href='/auth/logout']").click
  end
end
