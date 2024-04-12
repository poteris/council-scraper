# Looks up a council by name and scrapes the council's meetings and decisions in the last N weeks.
#
# @param name [String] The name of the council.
# @param num_weeks_back [Integer] The number of weeks back to scrape.
# @param num_weeks_forward [Integer] The number of weeks forward to scrape.
def scrape_council(name, num_weeks_back = 8, num_weeks_forward = 0)
  council = Council.find_by!(name: name)
  ((-1*num_weeks_forward)..(num_weeks_back-1)).each do |weeks_ago|
    date = Date.today - (weeks_ago * 7)
    beginning_of_week = date.beginning_of_week(:monday)

    ScrapeCouncilWorker.perform_async(council.id, beginning_of_week.to_s)
  end

  ScrapeDecisionsWorker.perform_async(council.id)
end

def classify_council(name)  
  council = Council.find_by!(name: name)

  council.decisions.where.missing(:decision_classifications).each do |decision|
    decision.classify!
  end

  council.meetings.each do |meeting|
    meeting.documents.where.missing(:document_classifications).where(is_minutes: true).each do |d|
      d.classify!
    end
  end
end
