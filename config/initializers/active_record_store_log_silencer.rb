module ActionDispatch
  module Session
    class ActiveRecordStore

      if Rails.env.development?
        alias :_write_session :write_session
        def write_session(env, sid, session_data, options)
          level = Rails.logger.level
          Rails.logger.level = Logger::INFO
          _write_session(env, sid, session_data, options)
          ensure
          Rails.logger.level = level
        end
      end

    end
  end
end