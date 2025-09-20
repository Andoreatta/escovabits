require "open3"
require "tempfile"
require "shellwords"
require "timeout"

class CompilationService
  COMPILER_TIMEOUT = 10 # Segundos

  def self.call(source_code:, language:, command_template:)
    new(source_code, language, command_template).call
  end

  def initialize(source_code, language, command_template)
    @source_code = source_code
    @language = language
    @command_template = command_template
  end

  def call
    file_extension = { "cpp" => ".cpp", "go" => ".go" }[@language] || ".tmp"
    temp_file = Tempfile.new([ "source", file_extension ])
    temp_file.write(@source_code)
    temp_file.close

    command = build_command(temp_file.path)

    if command.empty?
      return "Linguagem não suportada."
    end

    execute_command(command)
  ensure
    temp_file.unlink if temp_file
  end

  private

  def execute_command(command)
    stdout, stderr, status = nil
    begin
      Timeout.timeout(COMPILER_TIMEOUT) do
        stdout, stderr, status = Open3.capture3(*command)
      end

      if status.success?
        stdout
      else
        "Erro na compilação:\n" + stderr
      end
    rescue Timeout::Error
      "Erro: O tempo de compilação excedeu #{COMPILER_TIMEOUT} segundos."
    rescue => e
      "Erro ao executar o comando de compilação: #{e.message}"
    end
  end

  def build_command(file_path)
    # Substitui o placeholder %{file} pelo caminho real do arquivo temporário
    @command_template.map { |arg| arg == "%{file}" ? file_path : arg }
  end
end
