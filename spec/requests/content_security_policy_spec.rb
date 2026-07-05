require 'rails_helper'

RSpec.describe "Content Security Policy", type: :request do
  it "CSPが強制モード(Report-Onlyでない)で配信される" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.headers["Content-Security-Policy"]).to be_present
    expect(response.headers["Content-Security-Policy-Report-Only"]).to be_nil
  end

  it "script-srcが自前オリジン+アセットCDNに限定されている" do
    get root_path

    script_src = response.headers["Content-Security-Policy"][/script-src [^;]*/]
    expect(script_src).to include("'self'")
    expect(script_src).to include("https://assets.bokrium.com")
    expect(script_src).not_to include("https:;")
    expect(script_src).not_to include("'unsafe-inline'")
  end
end
