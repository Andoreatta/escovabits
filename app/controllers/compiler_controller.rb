class CompilerController < ApplicationController
  def index
  end

  def compile
    # Placeholder
    source_code = params[:source_code]
    compiler_options = params[:options]

    # Simulação
    @assembly_output = "Simulação:\nCompilando seu código...\n#{source_code.lines.first}"

    render partial: "assembly_output"
  end
end
