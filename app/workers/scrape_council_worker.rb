class ScrapeCouncilWorker
  include Sidekiq::Worker

  def perform(council_id, beginning_of_week_str)
    council_sync = CouncilSync.find_or_create_by!(council_id: council_id, week: beginning_of_week_str, kind: 'scrape')
    council_sync.update!(status: 'processing')

    sleep CouncilScraper::GLOBAL_DELAY
    council = Council.find(council_id)
    beginning_of_week = Date.parse(beginning_of_week_str)

    case council.council_type
    when Council.cmis
      Rails.logger.debug "fetching #{council.base_scrape_url}"
      agent = Mechanize.new
      agent.get(council.base_scrape_url)

      if (form = agent.forms & [0]) && (button = form.submits.filter { |s| s.value == 'Printer Friendly View' } & [0])
        form.click_button button
      end

      if agent.css('.rgHeader').filter { |h| h.text == 'Venue' }
        meeting_link = agent.css('.rgMasterTable a').first['href']
        calendar_link = meeting_link.gsub(
          /(tabid\/\d+)\/ctl\/\w+\/(mid\/\d+)\/.*/,
          "\1/ctl/MeetingCalendarPublicNoJava/\2/Date/#{beginning_of_week.strftime('%Y-%m-%d')}/Default.aspx"
        )
        agent.goto(calendar_link)
      end

      [0..6].map { |n| beginning_of_week + n.days }.each do |this_day|
        if (date_link = agent.xpath("//table//td[text()=\"#{this_day.strftime('%A, %-d %B')}\"]/following-sibling::td//a"))
          name = "Unknown committee"

          match = /\d{2}:\d{2}\s+(.*)/.match(date_link.text)
          name = match.captures[0] if match

          committee = council.committees.find_or_create_by!(name: name)

          meeting = council.meetings.find_or_create_by!(url: date_link['href'])
          meeting.update!(committee:, date: this_day)

          ScrapeMeetingWorker.new.perform(meeting.id)
        end
      end

      Rails.logger.debug links
    when Council.modern_gov
      url = make_url(council.base_scrape_url, beginning_of_week)
      Rails.logger.debug "fetching #{url}"
      base_domain = 'https://' + URI(url).host
      doc = get_doc(url)

      Rails.logger.debug beginning_of_week
      7.times do |day|
        block = doc.css('.mgCalendarWeekGrid')[day]
        next if block.nil?

        links = block.css('a').map { |link| URI.join(base_domain, link['href']).to_s }

        Rails.logger.debug links

        links.each do |link|
          Rails.logger.debug "fetching #{link}"
          sub_doc = get_doc(link)
          name = sub_doc.css('.mgSubTitleTxt').text
          committee_name = name.split(' - ')[0]
          committee = council.committees.find_or_create_by!(name: committee_name)

          meeting = council.meetings.find_or_create_by!(url: link)
          meeting.update!(name:, committee:, date: beginning_of_week + day.days)

          ScrapeMeetingWorker.new.perform(meeting.id)
        end
      end
    end

    council_sync.update!(status: 'processed', last_synced_at: Time.now.utc)
  end

  def get_doc(url)
    uri = URI(url)
    uri.host
    response = Net::HTTP.get_response(uri)
    Nokogiri::HTML(response.body)
  end

  def make_url(url, beginning_of_week)
    week_number = beginning_of_week.strftime('%W').to_i
    year = beginning_of_week.strftime('%Y').to_i

    url.gsub('mgCalendarMonthView.aspx',
             'mgCalendarWeekView.aspx') + "?WN=#{week_number}&CID=0&OT=&C=-1&MR=0&DL=0&ACT=Later&DD=#{year}"
  end
end
