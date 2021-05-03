module TibyBytes

  # CP-1252 decimal byte => UTF-8 approximation as an array of bytes
  CP1252 = {
    128 => [226, 130, 172],
    129 => nil,
    130 => [226, 128, 154],
    131 => [198, 146],
    132 => [226, 128, 158],
    133 => [226, 128, 166],
    134 => [226, 128, 160],
    135 => [226, 128, 161],
    136 => [203, 134],
    137 => [226, 128, 176],
    138 => [197, 160],
    139 => [226, 128, 185],
    140 => [197, 146],
    141 => nil,
    142 => [197, 189],
    143 => nil,
    144 => nil,
    145 => [226, 128, 152],
    146 => [226, 128, 153],
    147 => [226, 128, 156],
    148 => [226, 128, 157],
    149 => [226, 128, 162],
    150 => [226, 128, 147],
    151 => [226, 128, 148],
    152 => [203, 156],
    153 => [226, 132, 162],
    154 => [197, 161],
    155 => [226, 128, 186],
    156 => [197, 147],
    157 => nil,
    158 => [197, 190],
    159 => [197, 184]
  }

  module StringMixin

    # Attempt to replace invalid UTF-8 bytes with valid ones. This method
    # naively assumes if you have invalid UTF8 bytes, they are either Windows
    # CP-1252 or ISO8859-1. In practice this isn't a bad assumption, but may not
    # always work.
    #
    # Passing +true+ will forcibly tidy all bytes, assuming that the string's
    # encoding is CP-1252 or ISO-8859-1.
    def tidy_bytes(force = false)

      if force
        return unpack("C*").map do |b|
          tidy_byte(b)
        end.flatten.compact.pack("C*").unpack("U*").pack("U*")
      end

      bytes = unpack("C*")
      conts_expected = 0
      last_lead = 0

      bytes.each_index do |i|

        byte          = bytes[i]
        _is_ascii     = byte < 128
        is_cont       = byte > 127 && byte < 192
        is_lead       = byte > 191 && byte < 245
        is_unused     = byte > 240
        is_restricted = byte > 244

        # Impossible or highly unlikely byte? Clean it.
        if is_unused || is_restricted
          bytes[i] = tidy_byte(byte)
        elsif is_cont
          # Not expecting continuation byte? Clean up. Otherwise, now expect one less.
          conts_expected == 0 ? bytes[i] = tidy_byte(byte) : conts_expected -= 1
        else
          if conts_expected > 0
            # Expected continuation, but got ASCII or leading? Clean backwards up to
            # the leading byte.
            begin
              (1..(i - last_lead)).each {|j| bytes[i - j] = tidy_byte(bytes[i - j])}
            rescue NoMethodError
              next
            end
            conts_expected = 0
          end
          if is_lead
            # Final byte is leading? Clean it.
            if i == bytes.length - 1
              bytes[i] = tidy_byte(bytes.last)
            else
              # Valid leading byte? Expect continuations determined by position of
              # first zero bit, with max of 3.
              conts_expected = byte < 224 ? 1 : byte < 240 ? 2 : 3
              last_lead = i
            end
          end
        end
      end
      begin
        bytes.empty? ? nil : bytes.flatten.compact.pack("C*").unpack("U*").pack("U*")
      rescue ArgumentError
        nil
      end
    end

    # Tidy bytes in-place.
    def tidy_bytes!(force = false)
      replace tidy_bytes(force)
    end

    private

    def tidy_byte(byte)
      byte < 160 ? TibyBytes::CP1252[byte] : byte < 192 ? [194, byte] : [195, byte - 64]
    end

  end
end

class String
  include TibyBytes::StringMixin
end
