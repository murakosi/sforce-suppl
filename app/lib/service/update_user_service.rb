module Service
    class UpdateUserService
        include Service::ServiceCore
    
        def call(user, params)
            case params[:type]
            when :language then
                user.update_attributes(:language => params[:language])
            when :metadata_types then
                user.update_attributes(:metadata_types => params[:metadata_types])
            end

            user
        end   
    end
end