require "string_scanner"
require "http"

# based on ruby gem: https://github.com/asplake/link_header/blob/master/lib/link_header.rb

class LinkHeader
  def initialize
    @links = Hash(String, Hash(String, String)).new
  end

  def initialize(@links : Hash(String, Hash(String, String)))
  end

  def initialize(link_header : String)
    @links = LinkHeader.parse(link_header)
  end

  def initialize(headers : HTTP::Headers)
    @links = LinkHeader.parse(headers)
  end

  def initialize(response : HTTP::Client::Response)
    @links = LinkHeader.parse(response.headers)
  end

  getter links : Hash(String, Hash(String, String))

  def add(link : String, keys : Hash(String, String))
    @links[link] = keys
  end

  def to_s(io : IO) : Nil
    index = 0
    @links.each do |link, attrs|
      io << ", " if index > 0
      io << '<'
      io << link
      io << '>'
      attrs.each do |key, value|
        io << "; "
        io << key
        io << "=\""
        io << value.gsub('"', "\"")
        io << '"'
      end
      index += 1
    end
  end

  def fetch(key : String)
    found = nil
    @links.each do |link, attrs|
      if attrs["rel"]? == key
        found = link
        break
      end
    end
    found ? found : yield key
  end

  def fetch(key : String, default)
    fetch(key) { default }
  end

  # shortcut for looking up links matching rel
  def [](key : String) : String
    fetch(key) { raise KeyError.new "Missing link rel=#{key.inspect}" }
  end

  def []?(key : String) : String?
    fetch(key, nil)
  end

  def get(key : String)
    links = [] of String
    @links.each do |link, attrs|
      links << link if attrs["rel"]? == key
    end
    links
  end

  def self.parse(headers : HTTP::Headers) : Hash(String, Hash(String, String))
    if links = headers.get? "Link"
      # Can be multiple Link headers in a response
      # https://tools.ietf.org/html/rfc8288#section-3.5
      details = parse(links.shift)
      links.each do |link|
        details.merge! parse(link)
      end
      details
    else
      Hash(String, Hash(String, String)).new
    end
  end

  #
  # Regexes for link header parsing.  TOKEN and QUOTED in particular should conform to RFC2616.
  #
  # Acknowledgement: The QUOTED regexp is based on
  # http://stackoverflow.com/questions/249791/regexp-for-quoted-string-with-escaping-quotes/249937#249937
  #
  HREF   = / *< *([^>]*) *> *;? */               # :nodoc: note: no attempt to check URI validity
  TOKEN  = /([^()<>@,;:\"\[\]?={}\s]+)/          # :nodoc: non-empty sequence of non-separator characters
  QUOTED = /"((?:[^"\\]|\\.)*)"/                 # :nodoc: double-quoted strings with backslash-escaped double quotes
  ATTR   = /#{TOKEN} *= *(#{TOKEN}|#{QUOTED}) */ # :nodoc:
  SEMI   = /; */                                 # :nodoc:
  COMMA  = /, */                                 # :nodoc:

  def self.parse(link_header : String) : Hash(String, Hash(String, String))
    scanner = StringScanner.new(link_header)
    links = {} of String => Hash(String, String)
    while scanner.scan(HREF)
      href = scanner[1]
      attrs = {} of String => String
      while scanner.scan(ATTR)
        attr_name, token, quoted = scanner[1], scanner[3]?, scanner[4]?
        attrs[attr_name] = (token || quoted).not_nil!.gsub(/\\"/, '"')
        break unless scanner.scan(SEMI)
      end
      links[href] = attrs
      break unless scanner.scan(COMMA)
    end
    links
  end
end
