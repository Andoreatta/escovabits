class LanguageConfigService
  # Configurações para cada linguagem suportada
  LANGUAGES = {
    "cpp" => {
      hello_world: "#include <iostream>\n\nint main() {\n    std::cout << \"Hello, World!\";\n    return 0;\n}",
      extension: ".cpp",
      needs_outfile: false,
      command: ->(user_flags) {
        default_flags = %w[-fno-ident -fno-verbose-asm -fno-unwind-tables -masm=intel]
        [ "g++", "-S" ] + default_flags + user_flags + [ "%{file}", "-o", "-" ]
      }
    },
    "go" => {
      hello_world: "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Hello, World!\")\n}",
      extension: ".go",
      needs_outfile: true,
      command: ->(user_flags) {
        # As flags do usuário são passadas para -gcflags.
        gcflags = ([ "-S" ] + user_flags).join(" ")
        [ "go", "build", "-o", "%{outfile}", "-gcflags=#{gcflags}", "%{file}" ]
      }
    }
  }.freeze

  # Retorna o código "Hello World" para uma linguagem
  def self.hello_world_for(language)
    LANGUAGES.dig(language, :hello_world) || ""
  end

  # Retorna a extensão de arquivo para uma linguagem
  def self.extension_for(language)
    LANGUAGES.dig(language, :extension) || ".tmp"
  end

  # Verifica se a linguagem precisa de um arquivo de saída
  def self.needs_outfile?(language)
    LANGUAGES.dig(language, :needs_outfile) || false
  end

  # Constrói o comando de compilação para uma linguagem, incorporando flags do usuário
  def self.command_for(language, user_flags = [])
    command_proc = LANGUAGES.dig(language, :command)
    command_proc ? command_proc.call(user_flags) : []
  end
end
