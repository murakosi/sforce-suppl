class String

    def to_bool
        return self if self.class.is_a?(TrueClass) || self.class.is_a?(FalseClass)

        if self.downcase =~ /^(true|false)$/
            return true if $1 == 'true'
            return false if $1 == 'false'
        else
            raise NoMethodError.new("undefined method `to_bool' for '#{self}'")
        end
    end
end