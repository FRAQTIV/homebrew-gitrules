class GitrulesMcp < Formula
  desc "Assistant-agnostic MCP server exposing git rules & workflow tools"
  homepage "https://github.com/FRAQTIV/gitrules-mcp-server"
  url "https://github.com/FRAQTIV/gitrules-mcp-server/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "77e8aa029a48732e2af5a1fc43a5856b02a0fd29c0d0d829018650b6b2cfd6d3"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install"
    system "npm", "run", "build"
    libexec.install Dir["*"]
    chmod "+x", libexec/"dist/index.js"
    
    # Create MCP protocol wrapper using ES modules
    (libexec/"mcp-wrapper.js").write <<~EOS
      #!/usr/bin/env node

      import { spawn } from 'child_process';
      import { dirname, join } from 'path';
      import { fileURLToPath } from 'url';

      const __filename = fileURLToPath(import.meta.url);
      const __dirname = dirname(__filename);

      class MCPWrapper {
        constructor() {
          this.id = 0;
          this.initialized = false;
          this.tools = [];
          this.backendProcess = null;
        }

        async startBackend() {
          const backendPath = join(__dirname, 'dist', 'index.js');
          const nodeModulesPath = join(__dirname, 'node_modules');
          
          this.backendProcess = spawn('node', [backendPath, '--transport=stdio'], {
            stdio: ['pipe', 'pipe', 'pipe'],
            env: { ...process.env, NODE_PATH: nodeModulesPath }
          });

          await this.getToolList();
        }

        async getToolList() {
          return new Promise((resolve) => {
            const request = JSON.stringify({
              tool: 'server.info',
              id: 'init',
              input: {}
            });
            
            this.backendProcess.stdin.write(request + '\\n');
            
            this.backendProcess.stdout.once('data', (data) => {
              try {
                const response = JSON.parse(data.toString().trim());
                if (response.result && response.result.data && response.result.data.tools) {
                  this.tools = response.result.data.tools.map(tool => ({
                    name: tool.name,
                    description: tool.name,
                    inputSchema: {
                      type: "object",
                      properties: {},
                      required: []
                    }
                  }));
                }
                resolve();
              } catch (e) {
                resolve();
              }
            });
          });
        }

        send(message) {
          process.stdout.write(JSON.stringify(message) + '\\n');
        }

        async handleMessage(message) {
          if (message.method === 'initialize') {
            this.send({
              jsonrpc: "2.0",
              id: message.id,
              result: {
                protocolVersion: "2024-11-05",
                capabilities: { tools: {} },
                serverInfo: { name: "gitrules-mcp", version: "0.3.0" }
              }
            });
            return;
          }

          if (message.method === 'notifications/initialized') return;

          if (message.method === 'tools/list') {
            this.send({
              jsonrpc: "2.0",
              id: message.id,
              result: { tools: this.tools }
            });
            return;
          }

          if (message.method === 'tools/call') {
            const backendRequest = {
              tool: message.params.name,
              id: message.id,
              input: message.params.arguments || {}
            };
            
            this.backendProcess.stdin.write(JSON.stringify(backendRequest) + '\\n');
            
            this.backendProcess.stdout.once('data', (data) => {
              try {
                const backendResponse = JSON.parse(data.toString().trim());
                
                if (backendResponse.error) {
                  this.send({
                    jsonrpc: "2.0",
                    id: message.id,
                    error: {
                      code: -32000,
                      message: backendResponse.error.error.message
                    }
                  });
                } else {
                  this.send({
                    jsonrpc: "2.0",
                    id: message.id,
                    result: {
                      content: [{
                        type: "text",
                        text: JSON.stringify(backendResponse.result.data, null, 2)
                      }]
                    }
                  });
                }
              } catch (e) {
                this.send({
                  jsonrpc: "2.0",
                  id: message.id,
                  error: { code: -32000, message: "Failed to parse backend response" }
                });
              }
            });
            return;
          }

          this.send({
            jsonrpc: "2.0",
            id: message.id,
            error: { code: -32601, message: "Method not found" }
          });
        }
      }

      async function main() {
        const wrapper = new MCPWrapper();
        await wrapper.startBackend();

        let buffer = '';
        process.stdin.on('data', async (chunk) => {
          buffer += chunk.toString();
          let index;
          while ((index = buffer.indexOf('\\n')) >= 0) {
            const line = buffer.slice(0, index);
            buffer = buffer.slice(index + 1);
            
            if (line.trim()) {
              try {
                const message = JSON.parse(line);
                await wrapper.handleMessage(message);
              } catch (e) {
                // Invalid JSON, ignore
              }
            }
          }
        });

        process.stdin.on('end', () => {
          if (wrapper.backendProcess) wrapper.backendProcess.kill();
        });

        process.on('SIGINT', () => {
          if (wrapper.backendProcess) wrapper.backendProcess.kill();
          process.exit(0);
        });
      }

      main().catch(console.error);
    EOS
    
    chmod "+x", libexec/"mcp-wrapper.js"
    (bin/"mcp-git-rules").write_env_script libexec/"mcp-wrapper.js", NODE_PATH: "#{libexec}/node_modules"
  end

  test do
    # Test MCP initialization handshake
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
      assert parsed["result"]["serverInfo"]["name"] == "gitrules-mcp"
    end
  end
end
