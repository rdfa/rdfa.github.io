#! /usr/bin/env ruby
require 'bundler'
require "bundler/setup"
require 'getoptlong'
require_relative 'core'

cmd = ARGV.shift

OPT_ARGS = [
  ["--language", GetoptLong::REQUIRED_ARGUMENT,       "RDFa language to generate"],
  ["--num", GetoptLong::REQUIRED_ARGUMENT,            "Test Number"],
  ["--output", "-o", GetoptLong::REQUIRED_ARGUMENT,   "Output to specified path"],
  ["--verbose", GetoptLong::NO_ARGUMENT,              "Display details of processing"],
  ["--version", GetoptLong::REQUIRED_ARGUMENT,        "RDFa version to generate"],
  ["--help", "-?", GetoptLong::NO_ARGUMENT,           "This message"]
]
def usage
  width = OPT_ARGS.map do |o|
    l = o.first.length
    l += o[1].length + 2 if o[1].is_a?(String)
    l
  end.max
  STDERR.puts %{Usage: #{$0} manifest [options]}
  STDERR.puts %{       #{$0} input [options]}
  STDERR.puts %{       #{$0} query [options]}
  STDERR.puts %{       #{$0} result [options]}
  STDERR.puts %{Options:}
  OPT_ARGS.each do |o|
    s = "  %-*s  " % [width, (o[1].is_a?(String) ? "#{o[0,2].join(', ')}" : o[0])]
    s += o.last
    STDERR.puts s
  end
  exit(1)
end

opts = GetoptLong.new(*OPT_ARGS.map {|o| o[0..-2]})

options = {output: STDOUT}

opts.each do |opt, arg|
  case opt
  when '--output'       then options[:output] = File.open(arg, "w")
  when '--version'      then options[:version] = arg
  when '--num'          then options[:num] = arg
  when '--language'     then options[:language] = arg
  when '--verbose'      then options[:verbose] = true
  when "--help"         then usage
  end
end

unless %w(manifest input query result).include?(cmd)
  STDERR.puts "Unrecognized command #{cmd}"
  usage
end

STDERR.puts "Expected --version to be in #{Core.versions.inspect}" unless Core.versions.include?(options[:version])
STDERR.puts "Expected --language to be in #{Core.languages.inspect}" unless Core.languages.include?(options[:language])

case cmd
when 'manifest' then options[:output].puts Core.manifest_ttl(options[:version], options[:language])
when 'input'    then options[:output].puts Core.get_test_content(options[:version], options[:language], options[:num])
when 'query'    then options[:output].puts Core.get_test_content(options[:version], options[:language], options[:num], 'sparql')
when 'result'    then options[:output].puts Core.get_test_result(options[:version], options[:language], options[:num])
else usage
end
