class GitrulesMcp < Formula
  desc "Assistant-agnostic MCP server exposing git rules & workflow tools"
  homepage "https://github.com/FRAQTIV/gitrules-mcp-server"
  url "https://github.com/FRAQTIV/gitrules-mcp-server/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "77e8aa029a48732e2af5a1fc43a5856b02a0fd29c0d0d829018650b6b2cfd6d3"
  license "MIT"

  depends_on "node" => :build

  def install
    system "npm", "install"
    system "npm", "run", "build"
    libexec.install Dir["*"]
    chmod "+x", libexec/"dist/index.js"
    (bin/"mcp-git-rules").write_env_script libexec/"dist/index.js", NODE_PATH: "#{libexec}/node_modules"
  end

  test do
    # Just check the binary starts and prints a JSON line containing api_version
    IO.popen("#{bin}/mcp-git-rules --transport=stdio 2>/dev/null") do |io|
      line = io.gets
      assert_match "api_version", line
    end
  end
end
