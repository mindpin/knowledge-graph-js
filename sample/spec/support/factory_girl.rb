require 'database_cleaner'
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods

  config.before(:each) do
    begin
      DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end
end