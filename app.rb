require 'bundler'
Bundler.require
Dotenv.load

# https://github.com/jeremytregunna/ruby-trello#configuration
Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
  config.member_token = ENV['TRELLO_MEMBER_TOKEN']
end

def date_of_next(day)
  date  = Date.parse(day)
  delta = date > Date.today ? 0 : 7
  date + delta
end

def get_jobs_for_week(week)
  warn "Looking up jobs for week #{week}"
  morph_api_url = 'https://api.morph.io/chrismytton/gardeners-world-what-to-do-now/data.json'
  morph_api_key = ENV['MORPH_API_KEY']
  result = RestClient.get(morph_api_url, params: {
    key: morph_api_key,
    query: %Q{select section, job from 'data' where week = #{week}}
  })
  JSON.parse(result, symbolize_names: true)
end

week = Time.now.strftime('%W').to_i.succ

card_name = "Jobs for week #{week}"

list = Trello::List.find(ENV['TRELLO_LIST_ID'])

if list.board.cards.any? { |c| c.name == card_name }
  warn "Existing card found: #{card_name}"
  exit
end

card = Trello::Card.create(
  list_id: list.id,
  name: card_name,
  desc: "http://www.gardenersworld.com/what-to-do-now/",
  due: date_of_next("Monday").to_time.iso8601
)

list_names = {
  'around-garden-checklist' => 'Around the garden',
  'flowers-checklist' => 'Flowers',
  'fruit-veg-checklist' => 'Fruit and veg',
  'greenhouse-checklist' => 'Greenhouse'
}


items = get_jobs_for_week(week).group_by { |i| i[:section] }

items.each do |section_name, items|
  checklist = Trello::Checklist.create(card_id: card.id, name: list_names[section_name])
  items.each do |item|
    checklist.add_item(item[:job])
  end
end
