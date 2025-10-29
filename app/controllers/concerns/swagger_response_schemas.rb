module SwaggerResponseSchemas
  extend ActiveSupport::Concern

  included do
    include Swagger::Blocks

    # Note: ResponseWrapper and CollectionResponseWrapper schemas were removed
    # because they contained invalid Swagger 2.0 definitions (objects without
    # properties or $ref) that break old Swagger UI versions.
    # We now use explicit response schemas for each model instead.

    # Specific wrapped response schemas for each model
    swagger_schema :MemverseResponse do
      property :response do
        key :'$ref', :Memverse
      end
    end

    swagger_schema :MemverseCollectionResponse do
      property :response do
        key :type, :array
        items do
          key :'$ref', :Memverse
        end
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
      property :response do
        key :type, :array
        items do
          key :'$ref', :Passage
        end
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
      property :response do
        key :type, :array
        items do
          key :'$ref', :FinalVerse
        end
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

    swagger_schema :QuizResponse do
      property :response do
        key :'$ref', :Quiz
      end
    end

    swagger_schema :QuizCollectionResponse do
      property :response do
        key :type, :array
        items do
          key :'$ref', :Quiz
        end
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

    swagger_schema :ProgressReportResponse do
      property :response do
        key :'$ref', :ProgressReport
      end
    end

    swagger_schema :ProgressReportCollectionResponse do
      property :response do
        key :type, :array
        items do
          key :'$ref', :ProgressReport
        end
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