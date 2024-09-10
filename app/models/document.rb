class Document < ApplicationRecord
  belongs_to :meeting
  has_one :council, through: :meeting
  has_many :document_classifications

  has_one_attached :file

  PROCESSING_STATUSES = %w[waiting processing processed failed].freeze
  DOCUMENT_KINDS = %w[unclassified meeting_notes other].freeze # TODO: expand classifications

  scope :processed, -> { where(processing_status: 'processed') }
  scope :unprocessed, -> { where(processing_status: 'waiting') }
  scope :in_last, ->(days) { where('created_at >= ?', days.days.ago) }

  def extract_text!
    return unless pdf?
    return if text.present?

    EtagMatcher.match_url_etag(URI(url), etag, Proc.new {
      puts "Matched document etag for document #{id}, ignoring"
    }) do |etag|
      begin
        puts "fetching #{url}"
        response = HTTParty.get(url)

        Tempfile.create(['downloaded', '.pdf']) do |temp_pdf|
          temp_pdf.binmode
          temp_pdf.write(response.body)
          temp_pdf.rewind

          file.attach(io: temp_pdf, filename: "#{name.underscore.parameterize}.pdf", content_type: 'application/pdf')

          # Extract text from the PDF
          reader = PDF::Reader.new(temp_pdf.path)
          text = reader.pages.map(&:text).join("\n").gsub(/
  {2,}/, "\n").gsub("\u0000", "") # remove null bytes, multiple newlines
          update!(text: text, etag: etag, extract_status: 'success')

          puts "Indexing document #{id}"
          Integrations::Opensearch.new.index_object!(self)
        end
      rescue PDF::Reader::MalformedPDFError, HTTParty::RedirectionTooDeep => e
        update!(extract_status: 'failed')
      end
    end
  end

  def pdf?
    url.to_s.split('?')[0].end_with?('.pdf')
  end

  def classify!(model: nil)
    Integrations::ClassifyDocumentWorker.perform_async(id, model)
  end
end
