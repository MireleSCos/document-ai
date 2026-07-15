require "tempfile"
require "tmpdir"
require "fileutils"

module DocumentAi
  class FilePreparer
    ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/webp].freeze

    def initialize(uploaded_file)
      @uploaded_file = uploaded_file
      @paths = []
      @directory = nil
    end

    def call
      validate_size!
      return convert_pdf if uploaded_file.content_type == "application/pdf"
      return prepare_image if ALLOWED_IMAGE_TYPES.include?(uploaded_file.content_type)

      raise Error.new(
        "Formato não suportado: #{uploaded_file.content_type}",
        code: "unsupported_file_type"
      )
    end

    def cleanup
      paths.each { |entry| File.delete(entry[:path]) if File.exist?(entry[:path]) }
      FileUtils.remove_entry(directory) if directory && File.exist?(directory)
    end

    private

    attr_reader :uploaded_file, :paths, :directory

    def validate_size!
      maximum = ENV.fetch("DOCUMENT_AI_MAX_FILE_SIZE_MB", "15").to_i.megabytes
      return if uploaded_file.size <= maximum

      raise Error.new("Arquivo excede o limite", code: "file_too_large")
    end

    def prepare_image
      extension = File.extname(uploaded_file.original_filename)
      file = Tempfile.new(["document-ai-", extension])
      file.binmode
      file.write(uploaded_file.read)
      file.close
      paths << { path: file.path, content_type: uploaded_file.content_type }
    end

    def convert_pdf
      @directory = Dir.mktmpdir("document-ai-")
      input_path = File.join(directory, "document.pdf")
      output_prefix = File.join(directory, "page")
      File.binwrite(input_path, uploaded_file.read)

      max_pages = ENV.fetch("DOCUMENT_AI_MAX_PAGES", "5")
      success = system(
        "pdftoppm", "-png", "-r", "150",
        "-f", "1", "-l", max_pages,
        input_path, output_prefix,
        out: File::NULL, err: File::NULL
      )

      raise Error.new("Falha ao converter PDF", code: "pdf_conversion_failed") unless success

      pages = Dir["#{output_prefix}-*.png"].sort
      raise Error.new("PDF sem páginas legíveis", code: "empty_pdf") if pages.empty?

      pages.each { |path| paths << { path:, content_type: "image/png" } }
      paths
    end
  end
end
