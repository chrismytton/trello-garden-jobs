require 'bundler'
Bundler.require
Dotenv.load

# https://github.com/jeremytregunna/ruby-trello#configuration
Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
  config.member_token = ENV['TRELLO_MEMBER_TOKEN']
end

def get_jobs_for_month(month)
  warn "Looking up jobs for #{month}"
  morph_api_url = 'https://api.morph.io/chrismytton/gardeners-world-monthly-jobs/data.json'
  result = RestClient.get(morph_api_url, params: {
    key: ENV['MORPH_API_KEY'],
    query: %Q{select section, job from 'data' where month = "#{month}"}
  })
  JSON.parse(result, symbolize_names: true)
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
  desc: "Source: http://www.gardenersworld.com/what-to-do-now/\n\nScraper: https://morph.io/chrismytton/gardeners-world-monthly-jobs"
)

items = get_jobs_for_month(month).group_by { |i| i[:section] }

items.each do |section_name, items|
  checklist = Trello::Checklist.create(card_id: card.id, name: section_name)
  items.each do |item|
    checklist.add_item(item[:job])
  end
end
