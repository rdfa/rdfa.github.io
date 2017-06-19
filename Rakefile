require 'bundler'
require "bundler/setup"
require 'fileutils'
$:.unshift(File.expand_path("../_scripts", __FILE__))
require 'core'

namespace :test do
  desc 'Clean generated files'
  task :clean do
    Dir.glob("test-suite/rdfa*").each do |dir|
      FileUtils.rm_rf(dir)
    end
  end

  desc 'Create all test files'
  task :all => [:manifest, :input, :query, :result]

  desc 'Create manifests'
  task :manifest do
    %w(rdfa1.1 rdfa1.1-proc rdfa1.1-role rdfa1.1-vocab rdfa1.0).each do |version|
      %w(html4 html5 html5-invalid xhtml1 xhtml5 xhtml5-invalid svg xml).each do |language|
        next if Core.tests(version, language).empty?
        FileUtils.mkdir_p("test-suite/test-cases/#{version}/#{language}")
        File.open("test-suite/test-cases/#{version}/#{language}/manifest.ttl", "w") do |f|
          f.write Core.manifest_ttl(version, language)
        end
      end
    end
  end

  desc 'Create input files'
  task :input do
    %w(rdfa1.1 rdfa1.1-proc rdfa1.1-role rdfa1.1-vocab rdfa1.0).each do |version|
      %w(html4 html5 html5-invalid xhtml1 xhtml5 xhtml5-invalid svg xml).each do |language|
        suffix = case language
        when /xhtml/  then "xhtml"
        when /html/   then "html"
        when /svg/    then "svg"
        else               "xml"
        end

        Core.tests(version, language).each do |num|
          FileUtils.mkdir_p("test-suite/test-cases/#{version}/#{language}")
          File.open("test-suite/test-cases/#{version}/#{language}/#{num}.#{suffix}", "w") do |f|
            f.write Core.get_test_content(version, language, num)
          end
        end
      end
    end
  end

  desc 'Create query files'
  task :query do
    %w(rdfa1.1 rdfa1.1-proc rdfa1.1-role rdfa1.1-vocab rdfa1.0).each do |version|
      %w(html4 html5 html5-invalid xhtml1 xhtml5 xhtml5-invalid svg xml).each do |language|

        Core.tests(version, language).each do |num|
          FileUtils.mkdir_p("test-suite/test-cases/#{version}/#{language}")
          File.open("test-suite/test-cases/#{version}/#{language}/#{num}.sparql", "w") do |f|
            f.write Core.get_test_content(version, language, num, 'sparql')
          end
        end
      end
    end
  end

  desc 'Create result files'
  task :result do
    %w(rdfa1.1 rdfa1.1-proc rdfa1.1-role rdfa1.1-vocab rdfa1.0).each do |version|
      %w(html4 html5 html5-invalid xhtml1 xhtml5 xhtml5-invalid svg xml).each do |language|

        Core.tests(version, language).each do |num|
          FileUtils.mkdir_p("test-suite/test-cases/#{version}/#{language}")
          File.open("test-suite/test-cases/#{version}/#{language}/#{num}.ttl", "w") do |f|
            f.write Core.get_test_result(version, language, num)
          end
        end
      end
    end
  end
end
