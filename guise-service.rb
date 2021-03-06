require 'dalli'
module Guise
  class Service < Sinatra::Base
    register Sinatra::Async
    def authorized?
      if request.env['rack.request.query_hash']['key'].to_s == 'd4c524b30affeb984f3ed535a993e5b5b05ce431'
        true
      else
        false
      end
    end
    
    def json_correct(request, keys)
      json = request.env["rack.input"].read
      
      if json.nil?
        error(400, {:message => "JSON cannot be blank"}.to_json) 
      end
      
      begin
        json = JSON.parse(json)
      rescue Exception => e
        error(400, {:message => "Json is malformed: #{e.message}"}.to_json)
      end
      
      
      keys_there = keys.map {|k| json.has_key?(k)}.uniq
      
      if keys_there.include?(false)
        error(400, {:message => "JSON must have #{keys.join(' ')} assigned"}.to_json)
      end
      
      json
    end
    
    aget '/' do
      body("Battleshields operational")
    end
  
    apost '/vote.json', :provides => :json do
      error(401, {:message => "You are not authorized to post this"}.to_json) unless authorized?
    
      json = json_correct(request, %w[sentiment text])
      
      begin
        @response_code = SentimentEngine.vote(json['sentiment'], json['text'])
      rescue => e
        error(500, {:message => e.message}.to_json)
      end
      
      body({:message => @response_code}.to_json)
    end
    
    apost '/predictMany.json' do
      content_type 'application/json', :charset => 'utf-8'
      error(400, {:message => "Not available"}.to_json) unless defined?(SentimentEngine)
      begin
        json = json_correct(request, %w[texts])
        texts = json['texts']
        @resp = SentimentEngine.predict_many(texts)
        body(@resp.to_json)
      rescue => e
        body(e.backtrace)
      end
    end
  end
end

