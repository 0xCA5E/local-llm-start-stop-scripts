class LocalLlmStartStopScripts < Formula
  desc "Start/stop wrappers for Docker + Ollama + Open WebUI on macOS"
  homepage "https://github.com/example/local-llm-start-stop-scripts"
  head "https://github.com/example/local-llm-start-stop-scripts.git", branch: "main"
  license "MIT"

  depends_on "ollama"

  def install
    libexec.install "Start AI.command", "Stop AI.command", "Install Dependencies.command"
    bin.install "bin/local-llm-start", "bin/local-llm-stop", "bin/local-llm-doctor", "bin/local-llm-status", "bin/local-llm-cleanup"
  end

  def caveats
    <<~EOS
      Docker Desktop is also required.

      Install it with:
        brew install --cask docker

      Then open Docker Desktop once to complete first-run setup:
        open -a Docker

      Verify your environment:
        local-llm-doctor

      Quick checks and maintenance:
        local-llm-status
        local-llm-cleanup

      Rollback note:
        If wrapper behavior regresses, you can still run the underlying scripts directly:
        "$(brew --prefix)/Cellar/#{name}/#{version}/libexec/Start AI.command"
        "$(brew --prefix)/Cellar/#{name}/#{version}/libexec/Stop AI.command"
    EOS
  end

  test do
    assert_match "Usage: local-llm-doctor", shell_output("#{bin}/local-llm-doctor --help")
    assert_match "Usage: local-llm-status", shell_output("#{bin}/local-llm-status --help")
    assert_match "Usage: local-llm-cleanup", shell_output("#{bin}/local-llm-cleanup --help")
  end
end
