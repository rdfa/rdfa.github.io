require 'linkeddata'

##
# Core utilities used for generating and checking test cases
module Core
  HTMLRE = Regexp.new('([0-9]{4,4})\.xhtml')
  TCPATHRE = Regexp.compile('\$TCPATH')
  TESTS_PATH = File.expand_path("../../_data/tests", __FILE__)
  MANIFEST_JSON = File.expand_path("../../data/manifest.jsonld", __FILE__)
  HOSTNAME = 'rdfa.info'

  def url(offset)
    "http://#{HOSTNAME}#{offset}"
  end
  module_function :url

  ##
  # Make strings turtle """ safe
  #
  # @param [String] unsafe string
  # @return suitably escaped content
  def tesc(unsafe_string)
    # trailing " is bad
    unsafe_string.sub(/"$/, '\"')
  end
  module_function :tesc

  def manifest_entries
    @entries ||= ::JSON.load(File.read(MANIFEST_JSON))['@graph']
  end
  module_function :manifest_entries

  def versions
    @versions = manifest_entries.map {|e| e['versions']}.flatten.uniq
  end
  module_function :versions

  def languages
    @languages = manifest_entries.map {|e| e['hostLanguages']}.flatten.uniq
  end
  module_function :languages

  ##
  # Return the tests included for a particular version/language
  def tests(version, language)
    return [] if version == 'rdfa1.0' && !%w(html4 xhtml1 svg xml).include?(language)
    manifest_entries.select do |tc|
      tc['hostLanguages'].include?(language) && tc['versions'].include?(version)
    end.map {|tc| tc['num']}
  end
  module_function :tests

  ##
  # Return the Manifest source
  #
  # For version/language specific manifests, the MF syntax is used,
  # instead of TestQuery; this makes EARL reporting simpler.
  #
  # @param [String] version
  # @param [String] language
  def manifest_ttl(version, language)
    # Return specific subset of manifest based on host_language and version
    # with appropriate URI re-writing
    test_ttl = ""
    ttl = %{@base <#{url("/test-suite/test-cases/#{version}/#{language}/manifest")}> .
      @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
      @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
      @prefix mf: <http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#> .
      @prefix test: <http://www.w3.org/2006/03/test-description#> .
      @prefix rdfatest: <http://rdfa.info/vocabs/rdfa-test#> .

      <>  rdf:type mf:Manifest ;
          rdfs:comment "RDFa #{version} tests for #{language}" ;
          mf:entries (
      }.gsub(/^      /, '')
    manifest_entries.each do |tc|
      next unless tc['hostLanguages'].include?(language) && tc['versions'].include?(version)
      ttl << "      <##{tc['num']}>\n"
      test_ttl << %{
        <##{tc['num']}> a rdfatest:#{tc['expectedResults'] ? 'Positive' : 'Negative'}EvaluationTest;
          mf:name """Test #{tc['num']}: #{tesc(tc['description'])}""";
          rdfs:comment """#{tesc(tc['purpose'])}""";
          test:classification <#{tc['classification']}>;
          mf:action <#{get_test_url(version, language, tc['num'])}>;
          mf:result <#{get_test_url(version, language, tc['num'], 'ttl')}>;
        }.gsub(/^        /, '')
      test_ttl << %{  rdftest:queryParam "#{tc['queryParam']}";\n} unless tc['queryParam'].to_s.empty?
      test_ttl << %{  test:specificationReference """#{tesc(tc['reference'])}""";\n} unless tc['reference'].empty?
      test_ttl << %{  .\n}
    end

    # Output manifest definition, ordered tests and test definitions
    ttl << "  ) .\n"
    ttl + test_ttl
  end
  module_function :manifest_ttl

  ##
  # Return the document URL for a test or SPARQL
  #
  # @param [String] version "rdfa1.1" or other
  # @param [String] language "xhtml1", "html5" ...
  # @param [String] num "0001" or greater
  # @param [String] format
  #   "sparql", "xhtml", "xml", "html", "svg", or
  #   auto-detects from language
  # @return [String]
  def get_test_url(version, language, num, suffix = nil)
    suffix ||= case language
    when /xhtml/  then "xhtml"
    when /html/   then "html"
    when /svg/    then "svg"
    else               "xml"
    end

    url("/test-suite/test-cases/#{version}/#{language}/#{num}.#{suffix}").
      sub(/localhost:\d+/, HOSTNAME) # For local testing
   rescue
     "http://rdfa.info/test-suite/test-cases/#{version}/#{language}/#{num}.#{suffix}"
  end
  module_function :get_test_url

  ##
  # Get the content for a test
  #
  # @param [String] version "xhtml1", "html5" ...
  # @param [String] language "rdfa1.1" or other
  # @param [String] num "0001" or greater
  # @param [String] format "sparql", "ttl", nil
  # @return [{:root_attributes => {}, :content => String, :language => String, :version => String}]
  #   Serialized document and root attributes (including prefix mappings)
  def get_test_content(version, language, num, format = nil)
    suffix = case language
    when /xhtml/  then "xhtml"
    when /html/   then "html"
    when /svg/    then "svg"
    else               "xml"
    end

    filename = TESTS_PATH + "/#{num}.#{format == 'sparql' ? 'sparql' : 'txt'}"
    
    tcpath = url("/test-suite/test-cases/#{version}/#{language}") rescue "http://rdfa.info/test-suite/test-cases/#{version}/#{language}"
    tcpath.sub!(/localhost:\d+/, HOSTNAME) # For local testing

    # Read in the file, extracting prefix mappings and other root attributes
    found_head = format == 'sparql'
    in_json = false
    prefix_mappings = []
    root_attributes = []
    prefix_mappings_json= ""
    content = File.readlines(filename).map do |line|
      line.force_encoding(Encoding::UTF_8) if line.respond_to?(:force_encoding)
      case line
      when %r(<head)
        found_head ||= true
      when %r({)
        in_json ||= true
      end
    
      if found_head
        line
      else
        found_head = !!line.match(%r(http://www.w3.org/2000/svg))
        if in_json then
          prefix_mappings_json << line.strip
          in_json = false if line.include?("}")
        else
          root_attributes << line.strip
        end
        nil
      end
    end.compact.join("")
    content.force_encoding(Encoding::UTF_8) if content.respond_to?(:force_encoding)
  
    unless prefix_mappings_json.empty?
      ::JSON.parse(prefix_mappings_json).each do |prefix,iri|
        if version == 'rdfa1.0' then
          prefix_mappings << 'xmlns:' + prefix + '="' + iri + '"'
        else
          prefix_mappings << prefix + ": " + iri
        end
      end
      if version == 'rdfa1.0' then
        prefix_mappings = prefix_mappings.join(" ")
      else
        prefix_mappings = 'prefix="' + prefix_mappings.join(" ") + '"'
      end
    else
      prefix_mappings = ""
    end
    root_attributes = root_attributes.join("\n")
    root_attributes = ' ' + root_attributes unless root_attributes.empty?
    root_attributes = prefix_mappings + root_attributes
    root_attributes = ' ' + root_attributes unless prefix_mappings.empty?

    content.gsub!(HTMLRE, "\\1.#{suffix}")
    content.gsub!(TCPATHRE, tcpath)

    case format || suffix
    when 'sparql'
      content
    when 'html'
      if language == 'html4'
        %(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/MarkUp/DTD/html401-rdfa11-1.dtd">\n) +
        %(<html version="HTML+RDFa 1.1"#{root_attributes}>\n)
      else
        "<!DOCTYPE html>\n" +
        %(<html#{root_attributes}>\n)
      end +
      content +
      "</html>"
    when 'xml'
      %(<?xml version="1.0" encoding="UTF-8"?>\n<root#{root_attributes}>\n) +
      content +
      "</root>"
    when 'svg'
      %(<?xml version="1.0" encoding="UTF-8"?>\n<svg#{root_attributes}>\n) +
      content +
      "</svg>"
    when 'xhtml'
      %(<?xml version="1.0" encoding="UTF-8"?>\n) +
      if language == 'xhtml1' && version == 'rdfa1.0'
        %(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd">\n) +
        %(<html xmlns="http://www.w3.org/1999/xhtml" version="XHTML+RDFa 1.0"#{root_attributes}>\n)
      elsif language == 'xhtml1'
        %(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.1//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-2.dtd">\n) +
        %(<html xmlns="http://www.w3.org/1999/xhtml" version="XHTML+RDFa 1.1"#{root_attributes}>\n)
      else
        %(<!DOCTYPE html>\n<html xmlns="http://www.w3.org/1999/xhtml"#{root_attributes}>\n)
      end +
      content +
      "</html>"
    else
      raise "unknown format #{(format || suffix).inspect}"
    end
  end
  module_function :get_test_content

  ##
  # Get the expected test result in Turtle
  #
  # @param [String] version "xhtml1", "html5" ...
  # @param [String] language "rdfa1.1" or other
  # @param [String] num "0001" or greater
  # @param [String] format "sparql", "ttl", nil
  # @return [{:root_attributes => {}, :content => String, :language => String, :version => String}]
  #   Serialized document and root attributes (including prefix mappings)
  def get_test_result(version, language, num)
    suffix = case language
    when /xhtml/  then "xhtml"
    when /html/   then "html"
    when /svg/    then "svg"
    else               "xml"
    end
    tcpath = url("/test-suite/test-cases/#{version}/#{language}") rescue "http://rdfa.info/test-suite/test-cases/#{version}/#{language}/#{num}.#{suffix}"
    tcpath.sub!(/localhost:\d+/, HOSTNAME) # For local testing

    content = get_test_content(version, language, num)

    options = {}
    entry = manifest_entries.detect {|tc| tc['num'] == num}
    if entry['queryParam']
      opt, arg = entry['queryParam'].split('=').map(&:to_sym)
      options[opt] = arg
    end
    RDF::Turtle::Writer.buffer do |w|
      RDF::RDFa::Reader.new(content, base_uri: tcpath, prefixes: w.prefixes, **options) do |r|
        w << r
      end
    end
  end
  module_function :get_test_result
end
