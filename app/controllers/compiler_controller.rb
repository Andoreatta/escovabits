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

    command = build_command(language, compiler_flags)

    assembly_output = CompilationService.call(
      source_code: source_code,
      language: language,
      command_template: command
    )

    @assembly_output = AssemblyFilterService.call(assembly_output, language: language)

    render turbo_stream: turbo_stream.update(
      "output_frame",
      partial: "compiler/assembly_output",
      locals: { assembly_output: @assembly_output }
    )
  end

  def hello_world
    language = params[:language] || "cpp"
    render plain: HELLO_WORLDS.fetch(language, "")
  end

  private

  def build_command(language, user_flags)
    safe_flags = Shellwords.split(user_flags)

    case language
    when "cpp"
      # Flags para simplificar a saída do assembly e usar sintaxe Intel
      default_flags = %w[-fno-ident -fno-verbose-asm -fno-unwind-tables -masm=intel]
      [ "g++", "-S" ] + default_flags + safe_flags + [ "%{file}", "-o", "-" ]
    when "go"
      # Para Go, as flags vêm antes do comando compile
      [ "go", "tool", "compile" ] + safe_flags + [ "-S", "%{file}" ]
    end
  end
end
