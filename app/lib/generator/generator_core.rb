module Generator
    module GeneratorCore
    extend ActiveSupport::Concern
        class_methods do
            def generate(*args)
                new().generate(*args)
            end
        end
    end
end