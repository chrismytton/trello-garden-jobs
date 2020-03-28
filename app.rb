require 'bundler/setup'
require 'trello'
require 'rest-client'
require 'json'
require 'date'

# https://github.com/jeremytregunna/ruby-trello#configuration
Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
  config.member_token = ENV['TRELLO_MEMBER_TOKEN']
end

def jobs
  api_url = 'https://www.chrismytton.uk/gardeners-world-monthly-jobs/jobs.json'
  result = RestClient.get(api_url)
  JSON.parse(result)
end

month = Date::MONTHNAMES[Date.today.month]

card_name = "Garden jobs for #{month}"

list = Trello::List.find(ENV['TRELLO_LIST_ID'])

if list.board.cards.any? { |c| c.name == card_name }
  warn "Existing card found: #{card_name}"
  exit
end

card = Trello::Card.create(
  list_id: list.id,
  name: card_name,
  desc: "Source: http://www.gardenersworld.com/what-to-do-now/\n\nScraper: https://github.com/chrismytton/gardeners-world-monthly-jobs"
)

jobs[month].each do |section_name, items|
  checklist = Trello::Checklist.create(card_id: card.id, name: section_name)
  items.each do |item|
    checklist.add_item(item)
  end
end
