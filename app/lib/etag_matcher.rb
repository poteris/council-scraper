class EtagMatcher
  class << self
    # Checks whether a URL matches a given etag.
    # @param [URI] url the URI of the URL to fetch
    # @param [String] existing_etag the existing etag to match against
    # @param [Proc] if_matched a proc to run if the etag matches
    # @yield runs when the etag does _not_ match
    def match_url_etag(url, existing_etag, if_matched = nil)
      catch :etag_match do
        Net::HTTP.start(url.host) do |http|
          etag = http.head(url.path)['Etag']
          if etag.present? && existing_etag === etag
            throw :etag_match
          end
        end

        yield if block_given?

        return
      end

      if_matched.call if if_matched
    end
  end
end
