class ScrapeCouncilsWorker
  include Sidekiq::Worker

  # Scrapes the council's meetings and decisions in the last N weeks.
  #
  # @param num_weeks_back [Integer] The number of weeks back to scrape.
  # @param num_weeks_forward [Integer] The number of weeks forward to scrape.
  def perform(num_weeks_back = 12, num_weeks_forward = 8)
    CSV.foreach('data/councils.csv', headers: true) do |row|
      council = Council.find_or_create_by!(external_id: row['id'], council_type: Council.modern_gov)
      council.update!(name: row['name'], base_scrape_url: row['url'])
    end

    CSV.foreach('data/cmis_councils.csv', headers: true) do |row|
      council = Council.find_or_create_by!(external_id: row['id'], council_type: Council.cmis)
      council.update!(name: row['name'], base_scrape_url: row['url'])
    end

    Council.order(Arel.sql('RANDOM()')).each do |council|
      ((-1*num_weeks_forward)..(num_weeks_back-1)).each do |weeks_ago|
        date = Date.today - (weeks_ago * 7)
        beginning_of_week = date.beginning_of_week(:monday)

        ScrapeCouncilWorker.perform_async(council.id, beginning_of_week.to_s)
      end

      ScrapeDecisionsWorker.perform_async(council.id)
    end
  end
end
