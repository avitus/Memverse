class ThinkingSphinx::Middlewares::Middleware
  def initialize(app)
    @app = app
  end

  private

  attr_reader :app, :context
end
