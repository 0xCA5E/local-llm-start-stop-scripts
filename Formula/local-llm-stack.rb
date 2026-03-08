class LocalLlmStack < Formula
  desc "Local scripts to start/stop a macOS Docker + Ollama + Open WebUI stack"
  homepage "https://github.com/example/local-llm-start-stop-scripts"
  head "https://github.com/example/local-llm-start-stop-scripts.git", branch: "main"

  depends_on :macos

  def install
    libexec.install "Start AI.command"
    libexec.install "Stop AI.command"
    libexec.install "Install Dependencies.command"
    libexec.install "Clean AI.command"
    libexec.install "Doctor AI.command"

    (bin/"local-llm-start").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/Start AI.command" "$@"
    EOS

    (bin/"local-llm-stop").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/Stop AI.command" "$@"
    EOS

    (bin/"local-llm-install-deps").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/Install Dependencies.command" "$@"
    EOS

    (bin/"local-llm-clean").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/Clean AI.command" "$@"
    EOS

    (bin/"local-llm-doctor").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/Doctor AI.command" "$@"
    EOS

    (bin/"local-llm-status").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/Doctor AI.command" "$@"
    EOS
  end

  def caveats
    <<~EOS
      This formula is macOS-only and uses AppleScript (`osascript`) + Terminal.app automation.

      First-run Docker Desktop requirement:
        - Launch Docker Desktop once and complete onboarding/permissions prompts.
        - The stack start command waits for Docker daemon readiness, but cannot complete app setup prompts for you.

      Installed commands:
        - local-llm-install-deps
        - local-llm-start
        - local-llm-stop
        - local-llm-clean  (optional destructive teardown)
        - local-llm-doctor (status/health checks)
        - local-llm-status (alias for local-llm-doctor)
    EOS
  end

  test do
    assert_predicate bin/"local-llm-start", :exist?
    assert_predicate bin/"local-llm-stop", :exist?
    assert_predicate bin/"local-llm-clean", :exist?
    assert_predicate bin/"local-llm-doctor", :exist?
    assert_predicate bin/"local-llm-status", :exist?
  end
end
