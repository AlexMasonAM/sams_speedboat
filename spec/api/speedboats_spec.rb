require "rails_helper"

describe "Speedboats API", :type => :request do
  
  it "returns a list of speedboats" do
    FactoryGirl.create_list(:speedboat, 10)
    
    get "/api/speedboats" # acts as the speedboat api index
    
    expect(response).to have_http_status 200
    
    speedboats = JSON.parse(response.body)
    expect(speedboats.count).to eq(10)
  end
end