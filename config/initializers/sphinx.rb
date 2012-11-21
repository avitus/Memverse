# Load relevant classes from engines for search support
module ThinkingSphinx
	class Context
		def load_models
			Bloggity::BlogPost
		end
	end
end