require 'net/http'
require 'uri'
require 'openssl'
require 'nokogiri'

class DocFetcher
  class << self
    def recursive_get_pdfs(base_domain, doc_or_url, depth = 0)
      sleep CouncilScraper::GLOBAL_DELAY if defined?(CouncilScraper::GLOBAL_DELAY)

      return [] if doc_or_url.nil? || doc_or_url == false
      return [] if doc_or_url.is_a?(String) && !doc_or_url.start_with?('http')

      if doc_or_url.is_a?(String)
        puts "fetching #{doc_or_url}"
        doc_or_url = get_doc(doc_or_url)
      end

      return [] if doc_or_url.nil? || doc_or_url == false
      return [] if defined?(Mechanize::File) && doc_or_url.is_a?(Mechanize::File) && !doc_or_url.is_a?(Mechanize::Page)

      links = doc_or_url.css('.mgContent a, .mgLinks a, .DocumentListItem a').map { |link| link['href'].to_s }.compact.uniq.map do |link|
        clean_link = link.gsub(' ', '+')
        begin
          URI.join(base_domain, clean_link).to_s
        rescue URI::InvalidURIError, URI::InvalidComponentError
          nil
        end
      end.compact

      links.map do |link|
        main_url = link.split('?')[0]
        if main_url =~ /Document\.ashx|\.(pdf|docx?)$/i
          puts link
          link
        elsif depth < 2 && !(link =~ /mg(Calendar|MeetingAttendance|LocationDetails|IssueHistoryHome|IssueHistoryChronology|UserInfo|VCalendar|Member|ListCommittees|EPetition|Generic)\.aspx|uucoverpage|ieDocSearch|ecCatDisplay|ieLogon/) && link != base_domain && link != "#{base_domain}/"
          recursive_get_pdfs(base_domain, link, depth + 1)
        else
          []
        end
      end.flatten.uniq
    end

    def get_doc(url, limit = 10)
      return false if limit <= 0 || url.nil? || url.to_s.strip.empty?

      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = 10
      http.read_timeout = 25

      path = uri.respond_to?(:request_uri) ? uri.request_uri : uri.path
      request = Net::HTTP::Get.new(path)
      request['User-Agent'] = 'Mozilla/5.0 (compatible; CouncilGateway/1.0; +https://councilgateway.poteris.co.uk)'

      response = http.request(request)

      case response
      when Net::HTTPSuccess
        Nokogiri::HTML(response.body)
      when Net::HTTPRedirection
        location = response['location']
        return false if location.nil? || location.to_s.strip.empty?

        redirect_url = URI.join(url, location).to_s
        get_doc(redirect_url, limit - 1)
      else
        if (response.code.to_i == 403 || response.code.to_i == 429) && limit > 1
          sleep 1.5
          request['User-Agent'] = 'Ruby'
          retry_response = http.request(request)
          return Nokogiri::HTML(retry_response.body) if retry_response.is_a?(Net::HTTPSuccess)
        end
        false
      end
    rescue OpenSSL::SSL::SSLError, StandardError => e
      puts "DocFetcher error for #{url}: #{e.message}"
      false
    end
  end
end