class AssemblyFilterService
  # --- Configurações de Filtro por Linguagem ---
  FILTERS = {
    "cpp" => {
      # Mantivemos diretivas de dados (.string, .long, etc.) e de seção (.text, .data)
      # removendo-as da lista de filtros.
      directive_regex: /^\s*\.(file|loc|cfi_.*|def|endef|ident|scl|end|hidden|lcomm|intel_syntax|att_syntax|pushsection|popsection|previous|set|equ|skip|space|zero|rept|endr|if.*|else|endif|gnu_attribute|version|eabi_attribute|fpu|arch|thumb|thumb_func|fnstart|fnend|personality|lsda|handlerdata|reloc|fill|org)\b/,
      label_regex: /^\s*([.a-zA-Z_][\w$.@]*):/,
      comment_regex: /(\s+;.*$|\s+#.*$|\s+\/\/.*$)/,
      filter_numeric_labels: true
    },
    "go" => {
      # Go usa '//' para comentários e não tem diretivas com '.' como o g++
      directive_regex: /^\s*(TEXT|DATA|GLOBL|PCDATA|FUNCDATA|\.size|\.text|\.align|\.data|\.globl|\.pcalign|\.subsections_via_symbols)/,
      label_regex: /^\s*([.a-zA-Z_][\w$.<>*"]*):/, # Labels em Go podem ser mais complexos
      comment_regex: /\s+\/\/.*/,
      filter_numeric_labels: false
    }
  }.freeze

  def self.call(assembly_output, language: "cpp")
    new(assembly_output, language).call
  end

  def initialize(assembly_output, language)
    @assembly_output = assembly_output
    @language = language
    @config = FILTERS.fetch(language, FILTERS["cpp"]) # Usa cpp como padrão
  end

  def call
    return "" if @assembly_output.blank?

    lines = @assembly_output.lines
    # 1. Encontra todos os labels que são usados em instruções (ex: jmp .L1)
    used_labels = find_used_labels(lines)

    # 2. Processa as linhas, mantendo apenas o código essencial e os labels usados
    process_lines(lines, used_labels)
  end

  private

  def find_used_labels(lines)
    labels = Set.new
    lines.each do |line|
      # Ignora a definição do label em si (ex: .L1:) e diretivas
      line_content = line.strip
      next if line_content.match?(@config[:label_regex]) || line_content.start_with?(".")

      # Encontra labels usados como operandos
      # Ex: call .L1, jmp .L2, mov eax, OFFSET FLAT:.LC0
      line.scan(/[\s,]([.a-zA-Z_][\w$.@<>*#"]+)/).flatten.each do |label|
        labels.add(label)
      end
    end
    labels
  end

  def process_lines(lines, used_labels)
    result = []
    lines.each do |line|
      # Remove apenas comentários, mantendo a indentação original
      line_without_comment = line.sub(@config[:comment_regex], "")
      line_content = line_without_comment.strip

      next if line_content.empty?

      # Verifica se a linha é uma definição de label
      match = line_content.match(@config[:label_regex])
      if match
        label = match[1]
        # Mantém o label se ele for usado, for 'main', ou for um label de dados (ex: .LC0).
        if used_labels.include?(label) || label.match?(/main|^\.L[A-Z]/)
          result << line_content
        end
      # Ignora diretivas desnecessárias
      elsif !line_content.match?(@config[:directive_regex])
        # Adiciona a linha com sua indentação original preservada
        result << line_without_comment.rstrip
      end
    end
    # Junta as linhas, garantindo um espaçamento consistente.
    result.join("\n")
  end
end
