module MetadataHelper
    def metadata_directory
        metadata_client.describe_metadata_objects()
    end
end