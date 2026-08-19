class ScrapeMeetingWorker
  attr_reader :base_domain

  include Sidekiq::Worker

  def perform(meeting_id)
    sleep CouncilScraper::GLOBAL_DELAY
    meeting = Meeting.find(meeting_id)

    meeting_uri = URI(meeting.url)

    if meeting_uri.blank?
      puts "couldn't parse meeting URI for meeting #{meeting_id}, ignoring"
      return
    end

    EtagMatcher.match_url_etag(meeting_uri, meeting.etag, Proc.new {
      puts "Matched meeting etag for meeting #{meeting_id}, ignoring"
    }) do |etag|
      @base_domain = 'https://' + meeting_uri.host

      puts "fetching #{meeting.url}"
      meeting_doc = get_doc(meeting.url)

      pdfs = get_printed_minutes(meeting_doc, meeting.date, meeting.council.council_type)
      pdfs.each do |pdf|
        document = meeting.documents.find_or_create_by!(url: pdf)
        document.update!(is_minutes: true)
        document.extract_text!
      end

      pdfs = DocFetcher.recursive_get_pdfs(@base_domain, meeting_doc)
      pdfs.each do |pdf|
        document = meeting.documents.find_or_create_by!(url: pdf)
        document.extract_text!
      end

      media = get_media(meeting_doc)
      media.each do |media_url|
        document = meeting.documents.find_or_create_by!(url: media_url)
        document.update!(is_media: true)
      end

      meeting.update!(etag: etag)
    end
  end

  def get_printed_minutes(doc, meeting_date, council_type)
    if council_type.to_sym == :cmis
      minutes = doc.xpath(
        '//a[@class="TitleLink"][contains(@id, "cmisDocuments")][nokogiri:contains_insensitive(text(), "minutes", "notes")]',
        Class.new do
          def contains_insensitive(node_set, *possible_matches)
            node_set.find_all { |node| possible_matches.any? { |match| node.to_s.downcase.include? match } }
          end
        end.new
      )

      dated_minutes_links = minutes.map do |link|
        [link, Date.parse(link.text)]
      rescue Date::Error
        [link, nil]
      end

      if dated_minutes_links.any? { |link_and_date| link_and_date[1] != nil }
        this_minute = dated_minutes_links.select { |link| link[1] == meeting_date }&.first
        this_minute = dated_minutes_links.select { |link| link[1] == nil }&.first unless this_minute
      else
        this_minute = dated_minutes_links.first
      end

      this_minute ? [this_minute[0]['href']] : []
    else
      links = doc.css('.mgContent a, .mgActionList a')
                 .select do |link|
        link.content.downcase.include?('printed minutes') || link.content.downcase.include?('printed draft minutes')
      end
                 .map { |link| link['href'] }.compact.uniq

      puts 'FOUND IT' if links.length > 1

      links.map do |link|
        clean_link = link.gsub(' ', '+')
        begin
          URI.join(base_domain, clean_link).to_s
        rescue URI::InvalidURIError, URI::InvalidComponentError
          nil
        end
      end.compact
    end
  end

  def get_media(doc)
    script_content = doc.search('script').find { |script| script.content.include?('mgMeetingMedia') }

    if script_content
      # Extract the JSON-like string
      json_string = script_content.content.match(/mgMeetingMedia = new mgMediaPlayer\(mgJQuery, "mgMeetingMedia", (\[.*?\])/m)[1]

      # Parse the JSON-like string into a Ruby array
      media_info = JSON.parse(json_string)

      # Extract URLs
      return media_info.map { |media| media['Url'] }
    end

    []
  end

  def get_doc(url)
    agent = Mechanize.new
    agent.idle_timeout = 3 # seconds
    agent.open_timeout = 5 # seconds
    agent.read_timeout = 15 # seconds
    agent.get(url)
  rescue Mechanize::ResponseCodeError
    return false
  end
end
