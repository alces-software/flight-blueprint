#!/usr/bin/env ruby

require 'json'
require 'date'

def main
  if ARGV.length < 1 || ARGV.length > 2 || ARGV[0] == '--help' || ARGV[0] == '-h'
    usage
    exit 0
  end

  version_file = ARGV[0]

  previous_version = JSON.parse(File.read(version_file))
  new_version = {}

  current_year_month = Date.today.strftime("%Y%m")

  if previous_version['major'].to_s == current_year_month
    new_version['major'] = previous_version['major']
    new_version['minor'] = previous_version['minor'] + 1
  else
    new_version['major'] = current_year_month.to_i
    new_version['minor'] = 1
  end

  if ARGV[1] == '--dry-run'
    STDOUT.puts(new_version.to_json)
  else
    File.write(ARGV[0], new_version.to_json)
  end
end

def usage
  puts "Usage: #{$0} VERSION_FILE [options]"
  puts ""
  puts "      --dry-run\t\tprint the new version, don't update VERSION_FILE"
  puts "  -h, --help\t\tdisplay this help and exit"
end

main if __FILE__ == $0
