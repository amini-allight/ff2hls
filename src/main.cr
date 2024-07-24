#!/bin/crystal run
# ff2hls, a system for streaming local media files to HLS
# Copyright (C) 2024 Amini Allight
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
require "file"
require "dir"
require "colorize"
require "http/server"

macro error_404
    context.response.status_code = 404
    context.response.content_type = "text/plain"
    context.response.print "Not Found"
    next
end

def content_type(path : String) : String
    case path
    when .ends_with? ".html" then "text/html"
    when .ends_with? ".css" then "text/css"
    when .ends_with? ".js" then "application/ecmascript"
    when .ends_with? ".m3u8" then "application/vnd.apple.mpegurl"
    when .ends_with? ".ts" then "video/MP2T"
    when .ends_with? ".ico" then "image/x-icon"
    else raise Exception.new "Unknown file extension on path '#{path}'."
    end
end

HOST_ENV_VAR = "FF2HLS_HOST"
PORT_ENV_VAR = "FF2HLS_PORT"

if ENV.has_key?(PORT_ENV_VAR) && ENV[PORT_ENV_VAR].to_i?.nil?
    puts "Invalid value '#{ENV[PORT_ENV_VAR]}' supplied for environment variable '#{PORT_ENV_VAR}'.".colorize.red
    exit 1
end

HOST = ENV.has_key?(HOST_ENV_VAR) ? ENV[HOST_ENV_VAR] : "0.0.0.0"
PORT = ENV.has_key?(PORT_ENV_VAR) ? ENV[PORT_ENV_VAR].to_i : 8000
TMP_PATH = "tmp"
RES_PATH = "res"
RES_MARKER_PATH = "#{RES_PATH}/ff2hls-res-marker"

if !File.exists? RES_MARKER_PATH
    puts "The application must be run in the root directory of the repository.".colorize.red
    exit 1
end

input_path = ""
subtitle_input_path = ""

if ARGV.size == 1
    input_path = ARGV[0]
elsif ARGV.size == 2
    input_path = ARGV[0]
    subtitle_input_path = ARGV[1]
else
    puts "Usage: crystal run ./src/main.cr -- input-path [subtitle-input-path|subtitle-stream-index]"
    exit 1
end

if !File.exists? input_path
    puts "Input file '#{input_path}' could not be found.".colorize.red
    exit 1
end

if ARGV.size == 2 && subtitle_input_path.to_i?.nil? && !File.exists? subtitle_input_path
    puts "Subtitle input file '#{subtitle_input_path}' could not be found.".colorize.red
    exit 1
end

if File.exists? TMP_PATH
    if File.directory? TMP_PATH
        Dir.children(TMP_PATH).each do |child|
            if (!child.ends_with?(".m3u8") && !child.ends_with?(".ts") && !child.ends_with?(".vtt")) || !File.file?("#{TMP_PATH}/#{child}")
                puts "A file called '#{child}' exists in '#{TMP_PATH}' and we would need to delete it to clear the temporary directory. Exiting to avoid possible data loss. Please remove this file and then run the program again.".colorize.red
                exit 1
            end
        end

        Dir.children(TMP_PATH).each do |child|
            File.delete "#{TMP_PATH}/#{child}"
        end
    else
        puts "A file called '#{TMP_PATH}' exists and we would need to delete it to create the temporary directory. Exiting to avoid possible data loss. Please remove this file and then run the program again.".colorize.red
        exit 1
    end
else
    Dir.mkdir(TMP_PATH)
end

server = HTTP::Server.new do |context|
    path = context.request.path

    if path.includes? ".."
        error_404
    elsif path == "/"
        context.response.content_type = "text/html"
        context.response.print File.read("#{RES_PATH}/index.html")
    elsif path.ends_with?(".m3u8") || path.ends_with?(".ts")
        file_path = "#{TMP_PATH}/#{path}"

        if !File.exists? file_path
            error_404
        end

        context.response.content_type = content_type path
        context.response.print File.read(file_path)
    else
        file_path = "#{RES_PATH}/#{path}"

         if !File.exists? file_path
            error_404
         end

        context.response.content_type = content_type path
        context.response.print File.read(file_path)
    end
end

spawn do
    puts "Server online at #{HOST}:#{PORT}."
    server.listen HOST, PORT
end

puts "Starting video stream."
if ARGV.size == 2
    if subtitle_input_path.to_i?.nil?
        `ffmpeg -re -i "#{input_path}" -vf "subtitles='#{subtitle_input_path}'" -hls_time 4 -hls_playlist_type event -hls_segment_filename "#{TMP_PATH}/%08d.ts" "#{TMP_PATH}/stream.m3u8"`
    else
        `ffmpeg -re -i "#{input_path}" -vf "subtitles='#{input_path}':stream_index=#{subtitle_input_path}" -hls_time 4 -hls_playlist_type event -hls_segment_filename "#{TMP_PATH}/%08d.ts" "#{TMP_PATH}/stream.m3u8"`
    end
else
    `ffmpeg -re -i "#{input_path}" -hls_time 4 -hls_playlist_type event -hls_segment_filename "#{TMP_PATH}/%08d.ts" "#{TMP_PATH}/stream.m3u8"`
end
