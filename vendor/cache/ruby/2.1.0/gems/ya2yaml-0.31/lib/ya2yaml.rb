# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2006-2010 Akira FUNAI
# License::   MIT License

class Ya2YAML

  def initialize(opts = {})
    options = opts.dup
    options[:indent_size] = 2          if options[:indent_size].to_i <= 0
    options[:minimum_block_length] = 0 if options[:minimum_block_length].to_i <= 0
    options.update(
      {
        :printable_with_syck  => true,
        :escape_b_specific    => true,
        :escape_as_utf8       => true,
      }
    ) if options[:syck_compatible]

    @options = options
  end

  def _ya2yaml(obj)
    raise 'set $KCODE to "UTF8".' if (RUBY_VERSION < '1.9.0') && ($KCODE != 'UTF8')
    '--- ' + emit(obj, 1) + "\n"
  rescue SystemStackError
    raise ArgumentError, "ya2yaml can't handle circular references"
  end

  private

  def emit(obj, level)
    case obj
      when Array
        if (obj.length == 0)
          '[]'
        else
          indent = "\n" + s_indent(level - 1)
          obj.collect {|o|
            indent + '- ' + emit(o, level + 1)
          }.join('')
        end
      when Hash
        if (obj.length == 0)
          '{}'
        else
          indent = "\n" + s_indent(level - 1)
          hash_order = @options[:hash_order]
          if (hash_order && level == 1)
            hash_keys = obj.keys.sort {|x, y|
              x_order = hash_order.index(x) ? hash_order.index(x) : Float::MAX
              y_order = hash_order.index(y) ? hash_order.index(y) : Float::MAX
              o = (x_order <=> y_order)
              (o != 0) ? o : (x.to_s <=> y.to_s)
            }
          elsif @options[:preserve_order]
            hash_keys = obj.keys
          else
            hash_keys = obj.keys.sort {|x, y| x.to_s <=> y.to_s }
          end
          hash_keys.collect {|k|
            key = emit(k, level + 1)
            if (
              is_one_plain_line?(key) ||
              key =~ /\A(#{REX_BOOL}|#{REX_FLOAT}|#{REX_INT}|#{REX_NULL})\z/x
            )
              indent + key + ': ' + emit(obj[k], level + 1)
            else
              indent + '? ' + key +
              indent + ': ' + emit(obj[k], level + 1)
            end
          }.join('')
        end
      when NilClass
        '~'
      when String
        emit_string(obj, level)
      when TrueClass, FalseClass
        obj.to_s
      when Fixnum, Bignum, Float
        obj.to_s
      when Date
        obj.to_s
      when Time
        offset = obj.gmtoff
        off_hm = sprintf(
          '%+.2d:%.2d',
          (offset / 3600.0).to_i,
          (offset % 3600.0) / 60
        )
        u_sec = (obj.usec != 0) ? sprintf(".%.6d", obj.usec) : ''
        obj.strftime("%Y-%m-%d %H:%M:%S#{u_sec} #{off_hm}")
      when Symbol
        '!ruby/symbol ' + emit_string(obj.to_s, level)
      when Range
        '!ruby/range ' + obj.to_s
      when Regexp
        '!ruby/regexp ' + obj.inspect
      else
        case
          when obj.is_a?(Struct)
            struct_members = {}
            obj.each_pair{|k, v| struct_members[k.to_s] = v }
            '!ruby/struct:' + obj.class.to_s.sub(/^(Struct::(.+)|.*)$/, '\2') + ' ' +
            emit(struct_members, level + 1)
          else
            # serialized as a generic object
            object_members = {}
            obj.instance_variables.each{|k, v|
              object_members[k.to_s.sub(/^@/, '')] = obj.instance_variable_get(k)
            }
            '!ruby/object:' + obj.class.to_s + ' ' +
            emit(object_members, level + 1)
        end
    end
  end

  def emit_string(str, level)
    (is_string, is_printable, is_one_line, is_one_plain_line) = string_type(str)
    if is_string
      if is_printable
        if is_one_plain_line
          emit_simple_string(str, level)
        else
          (is_one_line || str.length < @options[:minimum_block_length]) ?
            emit_quoted_string(str, level) :
            emit_block_string(str, level)
        end
      else
        emit_quoted_string(str, level)
      end
    else
      emit_base64_binary(str, level)
    end
  end

  def emit_simple_string(str, level)
    str
  end

  def emit_block_string(str, level)
    str = normalize_line_break(str)

    indent = s_indent(level)
    indentation_indicator = (str =~ /\A /) ? indent.size.to_s : ''
    str =~ /(#{REX_NORMAL_LB}*)\z/
    chomping_indicator = case $1.length
      when 0
        '-'
      when 1
        ''
      else
        '+'
    end

    str.chomp!
    str.gsub!(/#{REX_NORMAL_LB}/) {
      $1 + indent
    }
    '|' + indentation_indicator + chomping_indicator + "\n" + indent + str
  end

  def emit_quoted_string(str, level)
    str = yaml_escape(normalize_line_break(str))
    if (str.length < @options[:minimum_block_length])
      str.gsub!(/#{REX_NORMAL_LB}/) { ESCAPE_SEQ_LB[$1] }
    else
      str.gsub!(/#{REX_NORMAL_LB}$/) { ESCAPE_SEQ_LB[$1] }
      str.gsub!(/(#{REX_NORMAL_LB}+)(.)/) {
        trail_c = $3
        $1 + trail_c.sub(/([\t ])/) { ESCAPE_SEQ_WS[$1] }
      }
      indent = s_indent(level)
      str.gsub!(/#{REX_NORMAL_LB}/) {
        ESCAPE_SEQ_LB[$1] + "\\\n" + indent
      }
    end
    '"' + str + '"'
  end

  def emit_base64_binary(str, level)
    indent = "\n" + s_indent(level)
    base64 = [str].pack('m')
    '!binary |' + indent + base64.gsub(/\n(?!\z)/, indent)
  end

  def string_type(str)
    if str.respond_to?(:encoding) && (!str.valid_encoding? || str.encoding == Encoding::ASCII_8BIT)
      return false, false, false, false
    end
    (ucs_codes = str.unpack('U*')) rescue (
      # ArgumentError -> binary data
      return false, false, false, false
    )
    if (
      @options[:printable_with_syck] &&
      str =~ /\A#{REX_ANY_LB}* | #{REX_ANY_LB}*\z|#{REX_ANY_LB}{2}\z/
    )
      # detour Syck bug
      return true, false, nil, false
    end
    ucs_codes.each {|ucs_code|
      return true, false, nil, false unless is_printable?(ucs_code)
    }
    return true, true, is_one_line?(str), is_one_plain_line?(str)
  end

  def is_printable?(ucs_code)
    # YAML 1.1 / 4.1.1.
    (
      [0x09, 0x0a, 0x0d, 0x85].include?(ucs_code)   ||
      (ucs_code <=     0x7e && ucs_code >=    0x20) ||
      (ucs_code <=   0xd7ff && ucs_code >=    0xa0) ||
      (ucs_code <=   0xfffd && ucs_code >=  0xe000) ||
      (ucs_code <= 0x10ffff && ucs_code >= 0x10000)
    ) &&
    !(
      # treat LS/PS as non-printable characters
      @options[:escape_b_specific] &&
      (ucs_code == 0x2028 || ucs_code == 0x2029)
    )
  end

  def is_one_line?(str)
    str !~ /#{REX_ANY_LB}(?!\z)/
  end

  def is_one_plain_line?(str)
    # YAML 1.1 / 4.6.11.
    str !~ /^([\-\?:,\[\]\{\}\#&\*!\|>'"%@`\s]|---|\.\.\.)/    &&
    str !~ /[:\#\s\[\]\{\},]/                                  &&
    str !~ /#{REX_ANY_LB}/                                     &&
    str !~ /^(#{REX_BOOL}|#{REX_FLOAT}|#{REX_INT}|#{REX_MERGE}
      |#{REX_NULL}|#{REX_TIMESTAMP}|#{REX_VALUE})$/x
  end

  def s_indent(level)
    # YAML 1.1 / 4.2.2.
    ' ' * (level * @options[:indent_size])
  end

  def normalize_line_break(str)
    # YAML 1.1 / 4.1.4.
    str.gsub(/(#{REX_CRLF}|#{REX_CR}|#{REX_NEL})/, "\n")
  end

  def yaml_escape(str)
    # YAML 1.1 / 4.1.6.
    str.gsub(/[^a-zA-Z0-9]/u) {|c|
      ucs_code, = (c.unpack('U') rescue [??])
      case
        when ESCAPE_SEQ[c]
          ESCAPE_SEQ[c]
        when is_printable?(ucs_code)
          c
        when @options[:escape_as_utf8]
          c.respond_to?(:bytes) ?
            c.bytes.collect {|b| '\\x%.2x' % b }.join :
            '\\x' + c.unpack('H2' * c.size).join('\\x')
        when ucs_code == 0x2028 || ucs_code == 0x2029
          ESCAPE_SEQ_LB[c]
        when ucs_code <= 0x7f
          sprintf('\\x%.2x', ucs_code)
        when ucs_code <= 0xffff
          sprintf('\\u%.4x', ucs_code)
        else
          sprintf('\\U%.8x', ucs_code)
      end
    }
  end

  module Constants
    UCS_0X85   = [0x85].pack('U')   #   c285@UTF8 Unicode next line
    UCS_0XA0   = [0xa0].pack('U')   #   c2a0@UTF8 Unicode non-breaking space
    UCS_0X2028 = [0x2028].pack('U') # e280a8@UTF8 Unicode line separator
    UCS_0X2029 = [0x2029].pack('U') # e280a9@UTF8 Unicode paragraph separator

    # non-break characters
    ESCAPE_SEQ = {
      "\x00" => '\\0',
      "\x07" => '\\a',
      "\x08" => '\\b',
      "\x0b" => '\\v',
      "\x0c" => '\\f',
      "\x1b" => '\\e',
      "\""   => '\\"',
      "\\"   => '\\\\',
    }

    # non-breaking space
    ESCAPE_SEQ_NS = {
      UCS_0XA0 => '\\_',
    }

    # white spaces
    ESCAPE_SEQ_WS = {
      "\x09" => '\\t',
      " "    => '\\x20',
    }

    # line breaks
    ESCAPE_SEQ_LB ={
      "\x0a"     => '\\n',
      "\x0d"     => '\\r',
      UCS_0X85   => '\\N',
      UCS_0X2028 => '\\L',
      UCS_0X2029 => '\\P',
    }

    # regexps for line breaks
    REX_LF   = Regexp.escape("\x0a")
    REX_CR   = Regexp.escape("\x0d")
    REX_CRLF = Regexp.escape("\x0d\x0a")
    REX_NEL  = Regexp.escape(UCS_0X85)
    REX_LS   = Regexp.escape(UCS_0X2028)
    REX_PS   = Regexp.escape(UCS_0X2029)

    REX_ANY_LB    = /(#{REX_LF}|#{REX_CR}|#{REX_NEL}|#{REX_LS}|#{REX_PS})/
    REX_NORMAL_LB = /(#{REX_LF}|#{REX_LS}|#{REX_PS})/

    # regexps for language-Independent types for YAML1.1
    REX_BOOL = /
       y|Y|yes|Yes|YES|n|N|no|No|NO
      |true|True|TRUE|false|False|FALSE
      |on|On|ON|off|Off|OFF
    /x
    REX_FLOAT = /
       [-+]?([0-9][0-9_]*)?\.[0-9.]*([eE][-+][0-9]+)? # (base 10)
      |[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*      # (base 60)
      |[-+]?\.(inf|Inf|INF)                           # (infinity)
      |\.(nan|NaN|NAN)                                # (not a number)
    /x
    REX_INT = /
       [-+]?0b[0-1_]+                   # (base 2)
      |[-+]?0[0-7_]+                    # (base 8)
      |[-+]?(0|[1-9][0-9_]*)            # (base 10)
      |[-+]?0x[0-9a-fA-F_]+             # (base 16)
      |[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+ # (base 60)
    /x
    REX_MERGE = /
      <<
    /x
    REX_NULL = /
       ~              # (canonical)
      |null|Null|NULL # (English)
      |               # (Empty)
    /x
    REX_TIMESTAMP = /
       [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] # (ymd)
      |[0-9][0-9][0-9][0-9]                       # (year)
       -[0-9][0-9]?                               # (month)
       -[0-9][0-9]?                               # (day)
       ([Tt]|[ \t]+)[0-9][0-9]?                   # (hour)
       :[0-9][0-9]                                # (minute)
       :[0-9][0-9]                                # (second)
       (\.[0-9]*)?                                # (fraction)
       (([ \t]*)Z|[-+][0-9][0-9]?(:[0-9][0-9])?)? # (time zone)
    /x
    REX_VALUE = /
      =
    /x
  end

  include Constants

end

class Object
  def ya2yaml(options = {})
    Ya2YAML.new(options)._ya2yaml(self)
  end
end

__END__
