require 'rails_helper'

RSpec.describe "Swagger UI", type: :request do
  describe "GET /api" do
    it "returns the Swagger UI HTML page" do
      get "/api"
      expect(response).to have_http_status(200)
      expect(response.content_type).to include("text/html")
    end

    it "includes all necessary Swagger UI JavaScript files" do
      get "/api"

      # Check for essential Swagger UI files
      expect(response.body).to include("swagger-ui.js")
      expect(response.body).to include("jquery-1.8.0.min.js")
      expect(response.body).to include("handlebars-2.0.0.js")
      expect(response.body).to include("backbone-min.js")
      expect(response.body).to include("underscore-min.js")
    end

    it "configures Swagger UI to load from /apidocs.json" do
      get "/api"
      expect(response.body).to include('url = "/apidocs.json"')
    end

    it "includes the Swagger UI initialization code" do
      get "/api"
      expect(response.body).to include("new SwaggerUi({")
      expect(response.body).to include("window.swaggerUi.load()")
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

    it "properly defines score parameter as single type string with formData" do
      get "/apidocs.json"
      json = JSON.parse(response.body)

      record_score_params = json["paths"]["/record_score"]["post"]["parameters"]
      score_param = record_score_params.find { |p| p["name"] == "score" }

      expect(score_param).not_to be_nil
      expect(score_param["type"]).to eq("string")
      expect(score_param["type"]).not_to be_an(Array)
      expect(score_param["in"]).to eq("formData")  # Should use formData, not body
    end
  end

  describe "Swagger UI assets" do
    it "serves the swagger-ui.js file" do
      get "/api/swagger-ui/swagger-ui.js"
      expect(response).to have_http_status(200)
      expect(response.content_type).to include("javascript")
    end

    it "serves jQuery library" do
      get "/api/swagger-ui/lib/jquery-1.8.0.min.js"
      expect(response).to have_http_status(200)
      expect(response.content_type).to include("javascript")
    end

    it "serves Handlebars library" do
      get "/api/swagger-ui/lib/handlebars-2.0.0.js"
      expect(response).to have_http_status(200)
      expect(response.content_type).to include("javascript")
    end

    it "serves CSS files" do
      get "/api/swagger-ui/css/screen.css"
      expect(response).to have_http_status(200)
      expect(response.content_type).to include("css")
    end
  end

  describe "Swagger UI functionality", js: true do
    it "can parse and display the Swagger documentation" do
      # This would be a Capybara test if we want to test the actual UI
      # For now, we'll just ensure the page loads without JavaScript errors
      visit "/api"

      # Check that the page has loaded
      expect(page).to have_css("#swagger-ui-container")

      # Wait for Swagger UI to initialize
      expect(page).to have_css(".swagger-ui-wrap", wait: 5)

      # Check for no JavaScript errors in console
      errors = page.driver.browser.logs.get(:browser)
                   .select { |e| e.level == "SEVERE" }
                   .reject { |e| e.message.include?("favicon") } # Ignore favicon 404s

      expect(errors).to be_empty, "JavaScript errors found: #{errors.map(&:message).join(', ')}"
    end if defined?(Capybara)
  end
end