require "rails_helper"

RSpec.describe "テスト環境" do
  it "test 環境で動いている" do
    expect(Rails.env).to eq "test"
  end

  it "テスト用のデータベースに接続している" do
    expect(ActiveRecord::Base.connection.select_value("SELECT DATABASE()")).to eq "minisocial_test"
  end

  it "テスト用のデータベースの文字コードが utf8mb4 であること" do
    expect(ActiveRecord::Base.connection.select_value("SELECT @@character_set_database")).to eq "utf8mb4"
  end
end
