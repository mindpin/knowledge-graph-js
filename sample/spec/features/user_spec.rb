require 'rails_helper'

RSpec.feature "Users", type: :feature do
  it "测试用户登录成功" do
    login_in create(:user)
  end
end
