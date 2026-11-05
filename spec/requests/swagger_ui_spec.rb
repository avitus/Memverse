require 'rails_helper'

RSpec.describe "Swagger UI", type: :request do
  describe "GET /api" do
    it "returns the Swagger UI HTML page" do
      get "/api"
      expect(response).to have_http_status(200)
      expect(response.content_type).to include("text/html")
    end

  end

  describe "GET /apidocs.json" do
    it "returns valid Swagger JSON" do
      get "/apidocs.json"
      expect(response).to have_http_status(200)
      expect(response.content_type).to include("application/json")

      json = JSON.parse(response.body)
      expect(json["swagger"]).to eq("2.0")
      expect(json["info"]["title"]).to eq("Swagger Memverse")
    end

    it "does not contain incompatible Swagger 2.0 features" do
      get "/apidocs.json"
      json_string = response.body

      # Check for problematic features that break old Swagger UI
      expect(json_string).not_to include("allOf")
      expect(json_string).not_to include("x-nullable")
      expect(json_string).not_to include("externalDocs")

      # Check for mixed type arrays (e.g., ["boolean", "string"])
      # This regex looks for type arrays with multiple types
      expect(json_string).not_to match(/"type"\s*:\s*\[[^\]]*"[^"]+"\s*,\s*"[^"]+"/m)
    end

    it "contains expected API endpoints" do
      get "/apidocs.json"
      json = JSON.parse(response.body)

      paths = json["paths"]
      expect(paths).to have_key("/users")
      expect(paths).to have_key("/users/{id}")
      expect(paths).to have_key("/memverses")
      expect(paths).to have_key("/verses/{id}")
      expect(paths).to have_key("/passages")
    end

    it "contains expected model definitions" do
      get "/apidocs.json"
      json = JSON.parse(response.body)

      definitions = json["definitions"]
      expect(definitions).to have_key("User")
      expect(definitions).to have_key("Memverse")
      expect(definitions).to have_key("Verse")
      expect(definitions).to have_key("Passage")
    end

    it "properly defines skippable field as single type string" do
      get "/apidocs.json"
      json = JSON.parse(response.body)

      memverse_schema = json["definitions"]["Memverse"]["properties"]["skippable"]
      expect(memverse_schema["type"]).to eq("string")
      expect(memverse_schema["type"]).not_to be_an(Array)
    end

    it "properly defines answer parameter as single type string with formData" do
      get "/apidocs.json"
      json = JSON.parse(response.body)

      record_score_params = json["paths"]["/record_score"]["post"]["parameters"]
      answer_param = record_score_params.find { |p| p["name"] == "answer" }

      expect(answer_param).not_to be_nil
      expect(answer_param["type"]).to eq("string")
      expect(answer_param["type"]).not_to be_an(Array)
      expect(answer_param["in"]).to eq("formData")  # Should use formData, not body
    end

    it "documents only the parameters record_score reads" do
      get "/apidocs.json"
      json = JSON.parse(response.body)

      names = json["paths"]["/record_score"]["post"]["parameters"].map { |p| p["name"] }

      expect(names).to contain_exactly("quiz_id", "question_num", "answer")
    end

    it "documents the record_score response body" do
      get "/apidocs.json"
      json = JSON.parse(response.body)

      responses = json["paths"]["/record_score"]["post"]["responses"]

      expect(responses["200"]["schema"]["properties"].keys).to contain_exactly("status", "score")
      expect(responses).to have_key("401")
    end

  end

  describe "Swagger UI functionality" do
    # NOTE: This test is disabled because it requires JavaScript system test setup
    # The Swagger UI functionality is verified through the request specs above
    # If we need to test the actual UI rendering, this should be moved to a system spec

    # it "can parse and display the Swagger documentation", type: :system, js: true do
    #   visit "/api"
    #   expect(page).to have_css("#swagger-ui-container")
    #   expect(page).to have_css(".swagger-ui-wrap", wait: 5)
    # end
  end
end