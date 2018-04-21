module Metadata
class HashFlatter
  def set(hash)
    @hash = hash
    @flatted = false
  end
  def flat
    @flatted = true
    @ret = {}
    @hash.each do |key, value|
      if value.class == Hash || value.class == ActiveSupport::HashWithIndifferentAccess
        value.each do |key_s, value_s|
          key_symbol = (key.to_s + '_' + key_s.to_s).to_sym
          @ret = @ret.merge({key_symbol => value_s})
          @flatted = false
        end
      else
        if value.class == Array
          value.each_with_index do |element, index|
            key_symbol = (key.to_s + '_' + index.to_s).to_sym
            @ret = @ret.merge ({key_symbol => element})
            @flatted = false
          end
        else
          @ret = @ret.merge ({key => value})
        end
      end
    end
  end
  def get
    @ret
  end
  def flatted?
    @flatted
  end

  def self.flat hash
    hf = HashFlatter.new
    hf.set hash
    hf.flat
    while hf.flatted? == false
      hf.set hf.get
      hf.flat
    end
    hf.get
  end

end
end