require 'rubygems'
require 'sinatra'
require 'erb'
require 'bencode'
require 'base32'
require 'rack/utils'
require 'cgi'

load 'torrentdb.rb'
load 'functions.rb'

get '/' do
  erb :index
end

post '/upload' do
  if params['torrent']
    tempfile = params['torrent'][:tempfile]
    tempfn   = params['torrent'][:filename]
    fn = save_torrent tempfn, tempfile
    if valid_file? fn
      @name = get_torrent_name fn
      @magnetlink = build_magnet_uri fn
      insert_torrent fn, @name, @magnetlink, split_input(params['tags'])
      FileUtils.rm fn
      erb :index
    else
      @error = "Bad torrent file formatting."
      FileUtils.rm fn
      erb :error
    end
  else
    @error = "No file uploaded."
    erb :error
  end
end

get '/search' do
  if params['q']
    unless params['q'].strip.gsub(/\s+/, ' ') =~ /^\s*$/
      @query = params['q']
      tags = split_input params['q']
      @torrents = torrents_from_tags tags
      erb :list
    else
      @error = "Search query was blank."
      erb :error
    end
  else
    @error = "No search query parameter passed."
    erb :error
  end
end

get '/latest/?:page?' do
  @torrents = latest_torrents 20, 5, params[:page].to_i
  erb :list
end

get '/magnet/:id' do
  if params[:id]
    t = get_torrent_by_id params[:id]
    unless t[:downloads]
      t[:downloads] = 1
    else
      t[:downloads] += 1
    end
    t.save!
    redirect t[:magnet]
  else
    @error = "No id parameter passed."
    erb :error
  end
end
