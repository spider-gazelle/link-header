# Crystal Lang HTTP Link Header Parser

[![CI](https://github.com/spider-gazelle/link-header/actions/workflows/ci.yml/badge.svg)](https://github.com/spider-gazelle/link-header/actions/workflows/ci.yml)

Parses link headers


## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     link-header:
       github: spider-gazelle/link-header
   ```

2. Run `shards install`


## Usage

```crystal

require "http/client"
require "link-header"

# Parse the links out of the response
response = HTTP::Client.get "http://www.example.com"
links = LinkHeader.new(response)

# equivalent to the above
links = LinkHeader.new(response.headers)

# Get the first link matching a `rel`
links["next"] # => "https://next.link/"  or raise KeyError
links["next"]? # => "https://next.link/" or nil

# Get all the links matching a `rel`
links.get("preconnect") # => ["https://link.1/", "https://link.2/"]
links.get("missing") # => []

```
