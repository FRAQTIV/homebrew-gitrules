class GitrulesMcp < Formula
  desc "Assistant-agnostic MCP server exposing git rules & workflow tools"
  homepage "https://github.com/FRAQTIV/fraqtiv-gitrules-MCP"
  url "https://github.com/FRAQTIV/gitrules-mcp-server/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "37ba1ddd0b38ba65576773144d42a628ffab89baf930bf22d66591e1c743b986"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install"
    system "npm", "run", "build"
    libexec.install Dir["*"]
    chmod "+x", libexec/"dist/index.js"
    (bin/"mcp-git-rules").write_env_script libexec/"dist/index.js", NODE_PATH: "#{libexec}/node_modules"
  end

  test do
    # Test MCP initialization handshake with native MCP support
    require "json"
    init_msg = {
      "jsonrpc" => "2.0",
      "id" => 1,
      "method" => "initialize",
      "params" => {
        "protocolVersion" => "2024-11-05",
        "clientInfo" => { "name" => "test-client", "version" => "1.0.0" }
      }
    }
    
    IO.popen("#{bin}/mcp-git-rules", "r+") do |io|
      io.puts(JSON.generate(init_msg))
      io.close_write
      response = io.gets
      parsed = JSON.parse(response)
      assert_equal "2.0", parsed["jsonrpc"]
      assert_equal 1, parsed["id"]
      assert parsed["result"]["capabilities"]
    end
  end
end
