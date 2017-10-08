require 'rest-client'
require 'discordrb'
require 'redis'
require 'json'

file = File.read('blob.json')
json = JSON.parse(file)
bot = Discordrb::Bot.new token: ENV['RBBY']

Thread.new do
  redis = Redis.new({host: 'redis'})
  redis.subscribe('RustPlayers') do |on|
    on.message do |channel, message|
      puts message
      bot.servers[183740337976508416].text_channels.select { |channel| channel.name == 'rust-server' }.first.send_message(message)
    end
  end
end

Thread.new do
  redis = Redis.new({host: 'redis'})
  redis.subscribe('newMinecraftPlayers') do |on|
    on.message do |channel, message|
      puts message
      bot.servers[183740337976508416].text_channels.select { |channel| channel.name == 'modded-minecraft-server' }.first.send_message(message)
    end
  end
end

bot.ready do
  bot.game = json['games'].sample
end

bot.member_join do |event|
  event.server.default_channel.send_message event.user.display_name + ' has joined! :wave:'
end

bot.member_leave do |event|
  event.server.text_channels.select { |channel| channel.name == 'debug' }.first.send_message event.user.username + ' just left the server!'
end

bot.message do |event|
  event.respond(message_engine(event.content)) if event.content[0] == '~' && event.content[1] != '~'
end

def message_engine(message)
  case message
  when '~fortune'
    '``' + `fortune -s | cowsay` + '``'
  when '~catpic'
    RestClient.get('http://thecatapi.com/api/images/get?format=src&type=jpg').request.url
  when '~catgif'
    RestClient.get('http://thecatapi.com/api/images/get?format=src&type=gif').request.url
  when '~chucknorris'
    JSON.parse(RestClient.get('http://api.icndb.com/jokes/random?exclude=[explicit]'))['value']['joke']
  when '~ghostbusters'
    '``' + `cowsay -f ghostbusters Who you Gonna Call` + '``'
  when '~moo'
    '``' + `apt-get moo` + '``'
  else
    if message.include?('~minecraft time')
      minecraft_command(message)
    else
      "I don't know that command. 😞"
    end
  end
end

bot.run
