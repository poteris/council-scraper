require 'net/http'

CMIS_URLS = %w[https://mid-ulster.cmis-ni.org/midulster/Councillors.aspx https://democracy.derby.gov.uk/cmis5/Councillors/tabid/62/ScreenMode/Alphabetical/Default.aspx http://cmis.daventrydc.gov.uk/daventry/Councillors/tabid/63/ScreenMode/Alphabetical/Default.aspx http://braintree.cmis.uk.com/braintree/Councillors.aspx https://cmis.norwich.gov.uk/live/Councillors.aspx http://cmis.essex.gov.uk/EssexCmis5/Councillors.aspx https://birmingham.cmis.uk.com/birmingham/Councillors.aspx https://southlanarkshire.cmis.uk.com/southlanarkshire/Councillors.aspx http://south-derbys.cmis.uk.com/south-derbys/Councillors.aspx https://great-yarmouth.cmis.uk.com/great-yarmouth/Councillors/tabid/63/ScreenMode/Alphabetical/Default.aspx https://midlothian.cmis.uk.com/live/Councillors.aspx https://eastsuffolk.cmis.uk.com/eastsuffolk/councillors.aspx https://carlisle.cmis.uk.com/CarlisleCityCouncillors.aspx http://cmis.dudley.gov.uk/cmis5/Councillors.aspx https://www.democracy.bolton.gov.uk/cmis5/People.aspx https://www.nottinghamshire.gov.uk/dms/Councillors/tabid/63/ScreenMode/Alphabetical/Default.aspx https://wdccmis.west-dunbarton.gov.uk/cmis5/Councillors.aspx https://cmis.northamptonshire.gov.uk/cmis5live/Councillors.aspx https://cambridgeshire.cmis.uk.com/ccc_live/Councillors.aspx https://cmis.hullcc.gov.uk/cmis/CouncillorsandSeniorOfficers/CouncillorsandSeniorOfficers.aspx https://cmispublic.walsall.gov.uk/cmis/Councillors.aspx https://perth-and-kinross.cmis.uk.com/perth-and-kinross/Councillors/OverviewofCouncillors.aspx https://estates8.warwickdc.gov.uk/cmis/ https://fylde.cmis.uk.com/fylde/CouncillorsandMP.aspx https://southstaffs.cmis.uk.com/Councillors.aspx http://democracy.luton.gov.uk/cmis5public/Councillors.aspx https://cmis.harborough.gov.uk/cmis5/Councillors.aspx https://norfolkcc.cmis.uk.com/norfolkcc/Councillors.aspx https://north-ayrshire.cmis.uk.com/north-ayrshire/Councillors/CurrentCouncillors.aspx https://renfrewshire.cmis.uk.com/renfrewshire/Councillors.aspx https://eastsuffolk.cmis.uk.com/eastsuffolk/councillors.aspx http://colchester.cmis.uk.com/colchester/Councillors.aspx https://committees.royalgreenwich.gov.uk/Councillors/tabid/63/ScreenMode/Alphabetical/Default.aspx https://moray.cmis.uk.com/moray/CouncilandGovernance/Councillors.aspx https://northlanarkshire.cmis.uk.com/Councillors.aspx https://committees.sunderland.gov.uk/committees/cmis5/Members.aspx https://rochford.cmis.uk.com/rochford/Members/tabid/62/ScreenMode/Alphabetical/Default.aspx].freeze

CMIS_URLS.each do |cmis_url|
  top_directory = URI.parse cmis_url
  catch :found_council do
    begin
      path_parts = top_directory.path.split('/')
      path_parts.pop # get rid of end aspx.
      path_parts.to_enum(:each_with_index).map {
        |part, index| "#{path_parts[0..index - 1].join('/')}/#{part}"
      }.filter { |path|
        !path.downcase.include?("councillors")
      }.sort_by(&:length).each do |path_part|
        %w[CalendarofMeetings Meetings MeetingsCalendar MeetingCalendar].each do |meetings_url|
          url = "#{top_directory.scheme}://#{top_directory.host}/#{path_part}/#{meetings_url}.aspx".gsub(/(?<!:)\/\/+/, '/')
          this_url = url
          resp = nil

          loop do
            resp = Net::HTTP.get_response(URI.parse(this_url))
            this_url = resp['location']
            break unless resp.is_a?(Net::HTTPRedirection)
          end

          if resp.code.to_i < 400
            puts "FOUND #{url}"
            throw :found_council
          else
            puts "NOT FOUND #{url}"
          end
        end
      end
    rescue => e
      puts "ERRORED #{top_directory.host}: #{e}"
    end
  end
end
