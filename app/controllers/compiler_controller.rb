require "open3"
require "tempfile"
require "shellwords"

class CompilerController < ApplicationController
  def index
    @source_code = LanguageConfigService.hello_world_for("cpp")
  end

  def compile
    source_code = params[:source_code]
    language = params[:language] || "cpp"
    compiler_flags = params[:compiler_flags] || ""

    command_template = LanguageConfigService.command_for(language, Shellwords.split(compiler_flags))

    assembly_output = CompilationService.call(
      source_code: source_code,
      language: language,
      command_template: command_template
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
    render plain: LanguageConfigService.hello_world_for(language)
  end
end
  private

  def build_command(language, user_flags)
    safe_flags = Shellwords.split(user_flags)

    case language
    when "cpp"
      default_flags = %w[-fno-ident -fno-verbose-asm -fno-unwind-tables -masm=intel]
      [ "g++", "-S" ] + default_flags + safe_flags + [ "%{file}", "-o", "-" ]
    when "go"
      # Usamos 'go build -gcflags="-S"' que lida com pacotes e imprime o assembly em stderr.
      # O executável resultante é direcionado para um arquivo temporário (%{outfile}) que é então descartado.
      # As flags do usuário são passadas para -gcflags.
      gcflags = ([ "-S" ] + safe_flags).join(" ")
      [ "go", "build", "-o", "%{outfile}", "-gcflags=#{gcflags}", "%{file}" ]
    end
  end
