require "open3"
require "tempfile"
require "shellwords"
require "timeout"

class CompilationService
  COMPILER_TIMEOUT = 10 # Segundos

  def self.call(source_code:, language:, flags:)
    new(source_code, language, flags).call
  end

  def initialize(source_code, language, flags)
    @source_code = source_code
    @language = language
    @flags = flags
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
    safe_flags = Shellwords.split(@flags)

    case @language
    when "cpp"
      [ "g++", "-S", "-fno-asynchronous-unwind-tables" ] + safe_flags + [ file_path, "-o", "-" ]
    when "go"
      [ "go", "tool", "compile" ] + safe_flags + [ "-S", file_path ]
    else
      []
    end
  end
end
