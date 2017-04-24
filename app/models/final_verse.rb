class FinalVerse < ActiveRecord::Base

  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [START]
  # ----------------------------------------------------------------------------------------------------------
  include Swagger::Blocks

  swagger_schema :FinalVerse do
    property :book do
      key :type, :string
    end
    property :chapter do
      key :type, :integer
      key :format, :int64
    end 
    property :last_verse do
      key :type, :integer
      key :format, :int64
    end           
  end
  # ----------------------------------------------------------------------------------------------------------
  # Swagger-Blocks DSL [END]
  # ----------------------------------------------------------------------------------------------------------
  
  # Validations
  validates_presence_of :book, :chapter, :last_verse

  protected
  
end