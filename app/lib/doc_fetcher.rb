class DocFetcher
  class << self
    def recursive_get_pdfs(base_domain, doc_or_url, depth = 0)
      sleep CouncilScraper::GLOBAL_DELAY

        return [] if doc_or_url.is_a?(String) && !doc_or_url.start_with?('http')

        if doc_or_url.is_a?(String)
        puts "fetching #{doc_or_url}"
        doc_or_url = get_doc(doc_or_url)
        end

        return [] if doc_or_url.is_a?(Mechanize::File) && !doc_or_url.is_a?(Mechanize::Page)
        return [] if doc_or_url == false

        links = doc_or_url.css('.mgContent a, .mgLinks a, .DocumentListItem a').map { |link| link['href'].to_s }.compact.uniq.map do |link|
        clean_link = link.gsub(' ', '+')
        begin
            URI.join(base_domain, clean_link).to_s
        rescue URI::InvalidURIError, URI::InvalidComponentError
            nil
        end
        end.compact
        pp links
        links.map do |link|
        main_url = link.split('?')[0]
        if main_url =~ /Document\.ashx|\.(pdf|docx?)$/i
            puts link
            link
        elsif depth < 2 && !(link =~ /mg(MeetingAttendance|LocationDetails|IssueHistoryHome|IssueHistoryChronology|UserInfo|VCalendar)\.aspx/)
            recursive_get_pdfs(base_domain, link, depth + 1)
        else
            []
        end
        end.flatten.uniq
    end

    def get_doc(url)
        uri = URI(url)
        host = uri.host
        response = Net::HTTP.get_response(uri)
        Nokogiri::HTML(response.body)
    rescue OpenSSL::SSL::SSLError
        false
    end
  end
end