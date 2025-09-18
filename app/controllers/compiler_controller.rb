require "open3"
require "tempfile"
require "shellwords"

class CompilerController < ApplicationController
  HELLO_WORLDS = {
    "cpp" => "#include <iostream>\n\nint main() {\n    std::cout << \"Hello, World!\";\n    return 0;\n}",
    "go" => "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Hello, World!\")\n}"
  }.freeze

  def index
    @source_code = HELLO_WORLDS["cpp"]
  end

  def compile
    source_code = params[:source_code]
    language = params[:language] || "cpp"
    compiler_flags = params[:compiler_flags] || ""

    @assembly_output = CompilationService.call(
      source_code: source_code,
      language: language,
      flags: compiler_flags
    )

    render partial: "compiler/assembly_output"
  end

  def hello_world
    language = params[:language] || "cpp"
    render plain: HELLO_WORLDS.fetch(language, "")
  end
end
  private

  def build_command(language, file_path, flags)
    # Sanitiza e divide as flags para evitar injeção de shell
    safe_flags = Shellwords.split(flags)

    case language
    when "cpp"
      [ "g++", "-S", "-fno-asynchronous-unwind-tables" ] + safe_flags + [ file_path, "-o", "-" ]
    when "go"
      # Para Go, as flags vêm antes do comando compile
      [ "go", "tool", "compile" ] + safe_flags + [ "-S", file_path ]
    else
      []
    end
  end
