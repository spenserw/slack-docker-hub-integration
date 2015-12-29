require 'bundler/setup'

require 'sinatra/base'
require 'rest-client'
require 'json'

class SlackDockerApp < Sinatra::Base
  get "/*" do
    params[:splat].first
  end
  post "/*" do
    docker = JSON.parse(request.body.read)

    #Docker Hub Data
    title_link = "<#{docker['repository']['repo_url']}|#{docker['repository']['repo_name']}>"

    #push data
    millis = "#{docker['push_data']['pushed_at']}"
    secs = sec = (millis.to_f / 1000).to_s
    date = Date.strptime(secs, '%s')
    
    user = "#{docker['push_data']['pusher']}"
    images = docker['push_data']['images']


    body = "[#{title_link}] new image build uploaded successfully.\n
            Changes pushed by #{user} on #{date}:\n
            #{images.join("\n")}
    "

    slack = { text: body }

    RestClient.post("https://hooks.slack.com/#{params[:splat].first}", payload: slack.to_json){ |response, request, result, &block|
        RestClient.post(docker['callback_url'], {state: response.code == 200 ? "success" : "error"}.to_json, :content_type => :json)
    }
  end
end

run SlackDockerApp
