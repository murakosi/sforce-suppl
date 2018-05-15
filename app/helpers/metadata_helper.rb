module MetadataHelper
    def metadata_directory
        Service::MetadataClientService.call(sforce_session).describe_metadata_objects()
    end
end