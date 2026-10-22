require "rails_helper"

RSpec.describe "トップページ", type: :request do
  # routes.rb に root がなく、ウェルカムページのルーティングは
  # 開発環境でしか追加されない（railties の finisher.rb）ため、テスト環境では 404 になる
  it "GET / は 404 を返す" do
    get "/"
    expect(response).to have_http_status(:not_found)
  end
end
