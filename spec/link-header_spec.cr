require "./spec_helper"

describe LinkHeader do
  it "should parse a link header" do
    raw_header = %(<https://one.example.com>; rel="preconnect", <https://two.example.com>; rel="preconnect", <https://three.example.com>; rel="preconnect")

    link = LinkHeader.new raw_header
    link.links.should eq({
      "https://one.example.com"   => {"rel" => "preconnect"},
      "https://two.example.com"   => {"rel" => "preconnect"},
      "https://three.example.com" => {"rel" => "preconnect"},
    })
    link.get("preconnect").should eq(["https://one.example.com", "https://two.example.com", "https://three.example.com"])
    link.to_s.should eq(raw_header)

    link["unknown"]?.should eq(nil)
    expect_raises(KeyError, "Missing link rel=\"unknown\"") { link["unknown"] }
  end

  it "should parse a Header object" do
    headers = HTTP::Headers.new
    headers["Link"] = [%(<https://example.org/>; rel="start"), %(<https://example.org/index>; rel="index")]

    link = LinkHeader.new headers
    link.links.should eq({
      "https://example.org/"      => {"rel" => "start"},
      "https://example.org/index" => {"rel" => "index"},
    })
    link["index"].should eq("https://example.org/index")
    link["start"].should eq("https://example.org/")
  end

  it "should parse a link header with unquoted attributes" do
    raw_header = %(<https://meraki.com/api/v1>; rel=first, <https://n293.meraki.com/api/v1/networks>; rel=next)
    link = LinkHeader.new raw_header
    link.links.should eq({
      "https://meraki.com/api/v1"               => {"rel" => "first"},
      "https://n293.meraki.com/api/v1/networks" => {"rel" => "next"},
    })
  end
end
