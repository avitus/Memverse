module SwaggerResponseSchemas
  extend ActiveSupport::Concern

  included do
    include Swagger::Blocks

    # Base response wrapper for single objects
    swagger_schema :ResponseWrapper do
      property :response do
        key :type, :object
        key :description, 'The actual response data'
      end
    end

    # Collection response wrapper for paginated results
    swagger_schema :CollectionResponseWrapper do
      property :response do
        key :type, :array
        key :description, 'Array of response objects'
      end
      property :count do
        key :type, :integer
        key :description, 'Total number of items'
      end
      property :page do
        key :type, :integer
        key :description, 'Current page number'
      end
      property :page_count do
        key :type, :integer
        key :description, 'Total number of pages'
      end
      property :per_page do
        key :type, :integer
        key :description, 'Items per page'
      end
      property :pagination do
        key :type, :object
        property :pages do
          key :type, :integer
          key :description, 'Total number of pages'
        end
        property :count do
          key :type, :integer
          key :description, 'Total number of items'
        end
      end
    end

    # Specific wrapped response schemas for each model
    swagger_schema :MemverseResponse do
      property :response do
        key :'$ref', :Memverse
      end
    end

    swagger_schema :MemverseCollectionResponse do
      allOf do
        schema do
          key :'$ref', :CollectionResponseWrapper
        end
        schema do
          property :response do
            key :type, :array
            items do
              key :'$ref', :Memverse
            end
          end
        end
      end
    end

    swagger_schema :VerseResponse do
      property :response do
        key :'$ref', :Verse
      end
    end

    swagger_schema :VerseArrayResponse do
      property :response do
        key :type, :array
        items do
          key :'$ref', :Verse
        end
      end
    end

    swagger_schema :PassageResponse do
      property :response do
        key :'$ref', :Passage
      end
    end

    swagger_schema :PassageCollectionResponse do
      allOf do
        schema do
          key :'$ref', :CollectionResponseWrapper
        end
        schema do
          property :response do
            key :type, :array
            items do
              key :'$ref', :Passage
            end
          end
        end
      end
    end

    swagger_schema :TranslationArrayResponse do
      property :response do
        key :type, :array
        items do
          key :'$ref', :TranslationGroup
        end
      end
    end

    swagger_schema :FinalVerseResponse do
      property :response do
        key :'$ref', :FinalVerse
      end
    end

    swagger_schema :FinalVerseCollectionResponse do
      allOf do
        schema do
          key :'$ref', :CollectionResponseWrapper
        end
        schema do
          property :response do
            key :type, :array
            items do
              key :'$ref', :FinalVerse
            end
          end
        end
      end
    end

    swagger_schema :QuizResponse do
      property :response do
        key :'$ref', :Quiz
      end
    end

    swagger_schema :QuizCollectionResponse do
      allOf do
        schema do
          key :'$ref', :CollectionResponseWrapper
        end
        schema do
          property :response do
            key :type, :array
            items do
              key :'$ref', :Quiz
            end
          end
        end
      end
    end

    swagger_schema :ProgressReportResponse do
      property :response do
        key :'$ref', :ProgressReport
      end
    end

    swagger_schema :ProgressReportCollectionResponse do
      allOf do
        schema do
          key :'$ref', :CollectionResponseWrapper
        end
        schema do
          property :response do
            key :type, :array
            items do
              key :'$ref', :ProgressReport
            end
          end
        end
      end
    end

    swagger_schema :UserResponse do
      property :response do
        key :'$ref', :User
      end
    end

    swagger_schema :UserMinimalResponse do
      property :response do
        key :'$ref', :UserMinimal
      end
    end

    # Simple message response
    swagger_schema :MessageResponse do
      property :response do
        key :type, :object
        property :message do
          key :type, :string
        end
        property :score do
          key :type, :integer
        end
      end
    end

    # Empty response for 204 No Content
    swagger_schema :NoContentResponse do
      key :description, 'No content'
    end
  end
end