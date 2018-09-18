# Introduction

This repository controls the [rdfa.info](http://rdfa.info/) website, including the
[RDFa Test Suite](http://rdfa.info/test-suite).

# RDFa Test Suite

The RDFa Test Suite is a set of Web Services, markup and tests that can 
be used to verify RDFa Processor conformance to the set of specifications
that constitute RDFa 1.1. The goal of the suite is to provide an easy and 
comprehensive RDFa testing solution for developers creating RDFa Processors.

## Design

The RDFa Test suite allows developers to mix and match RDFa processor endpoints
with different RDFa versions and Host Languages.

The RDFa Test Suite is an single-page HTML application driving the entire
process.

The page is loaded with the complete lists of tests associated with different RDFa versions and host languages.
To execute a test, the application uses the `processorUrl` and appends URI query parameters identifying the test source and other necessary parameters, upon which the processor will return the parsed RDF represented as either [N-Triples]() or [Turtle](). As the processor executes in HTML, it is important that the processor return the header `Access-Control-Allow-Origin: *`.
The application also fetches an associated SPARQL query, which
uses an _ASK_ form to return true or false.

The test-suite is implemented using [JavaScript](https://en.wikipedia.org/wiki/JavaScript) and  [rdflib.js](https://github.com/linkeddata/rdflib.js/).
The user interface is implemented in JavaScript using
[Bootstrap.js][] and [Backbone.js][].

The test files are managed statically using [Jekyll][] with a [Rake task](https://en.wikipedia.org/wiki/Rake_(software)) used to build version- and language-specific test files.

The HTML application is implemented principally in JavaScript using [Backbone.js][] as a model-viewer-controller, which downloads the test suite manifest and creates a simple user interface using [Bootstrap.js][] to run tests, or get test details.

Processing happens in the following order:

    RDFa Test Suite | RDFa Website | RDFa Processor
    load webpage    ->
                    <- test scaffold
    load manifest   ->
                    <- JSON-LD manifest
    run test        -> Load SPARQL query.
                                    -> Process referenced
                                       test document and
                                       return RDF with
                                       Content-Type indicating
                                    <- format.
    SPARQL runs with
    returned document
    returning _true_
    or _false_.

    display results

## Running the test suite

You can view and run this test suite at the following URL:

[http://rdfa.info/test-suite](http://rdfa.info/test-suite)

## How to add a unit test

In order to add a unit test, you must follow these steps:
   
1. Pick a new unit test number. For example - 250. To be consistent, please use
   the next available unit test number.
2. Create a markup file in the tests/ directory with a .txt extension. 
   For example: tests/250.txt
3. Create a SPARQL query file in the tests/ directory with a .sparql extension.
   For example: tests/250.sparql
4. Add your test to manifest.ttl and indicate the host language(s) and version(s) for which
   it applies. For example, if you would like your example to only apply to HTML4,
   you would specify ```rdfatest:hostLanguage "html4";``` in the test case entry.

There are three classifications for Unit Tests:

* required - These are tests that are required for proper operation per the
           appropriate RDFa specification.
* optional - These are tests for optional features supported by some RDFa 
           Processors.
* buggy    - These are tests that are buggy or are not considered valid test
           cases by all RDFa processor maintainers.

The test suite is designed to empower RDFa processor maintainers to create
and add tests as they see fit. This may mean that the test suite may become
unstable from time to time, but this approach has been taken so that the 
long-term goal of having a comprehensive test suite for RDFa can be achieved
by the RDFa community.

When running locally, after adding a unit test, run `rake cache:clear` to remove cached files and ensure that necessary HTTP resources are regenerated. For the deployed website, this happens automatically each time a Git commit is pushed to the server.

## How to create a processor endpoint.

The Test Suite operates by making a call to a _processor endpoint_ with a query parameter that indicates
the URL of the test document to be processed. Within the test suite, a text box (upper right-hand corner)
allows a processor endpoint to be selected or added manually. It is presumed that the endpoint URL ends
with a query parameter to which a test URL can be appended. For example, the _pyrdfa_ endpoint is
defined as follows: `http://www.w3.org/2012/pyRdfa/extract?uri=`. When invoked, the URL of an actual
test will be appended, such as the following:
`http://www.w3.org/2012/pyRdfa/extract?uri=http://rdfa.info/test-suite/test-cases/xml/rdfa1.1/0001.xml`.

Everything required by a processor can be presumed from the content of the document provided, however
the test suite will also set a `Content-Type` HTTP header appropriate for the document provided, these include
* application/xhtml+xml,
* application/xml,
* image/svg+xml, and
* text/html

The processor is called with HTTP Accept header indicating appropriate result formats (currently,
`text/turtle` (indicating [Turtle](http://www.w3.org/TR/turtle/)),
`application/rdf+xml` (indicating [RDF/XML](http://www.w3.org/TR/rdf-syntax-grammar/)), and
`text/plain` (indicating [N-Triples](http://www.w3.org/TR/rdf-testcases/#ntriples))), and the processor may
respond with an appropriate RDF format. Processors _SHOULD_ set the HTTP `Content-Type` of the resulting
document to the associated document Mime Type.

In some cases, the test suite may add additional query parameters to the endpoint URL to test different
required or optional behaviors, these include `rdfagraph`, taking a value of `original`, `processor`, or
`original,processor` to control the processor output
(see [RDFa Core 1.1 Section 7.6.1](http://www.w3.org/TR/rdfa-core/#accessing-the-processor-graph)).
Also, `vocab_expansion` taking any value is used
to control optional RDFa vocabulary expansion
(see [RDFa Core 1.1 Section 10.2](http://www.w3.org/TR/rdfa-core/#s_expansion_control)).

To add a processor to the test suite, add to the object definition in
`processors.json` in alphabetical order. This is currently defined as follows:

    {
      "any23 (Java)": {
        "endpoint": "http://any23.org/turtle/",
        "doap": "http://any23.org/",
        "doap_url": "/earl-reports/any23-doap.ttl"
      },
      "clj-rdfa (Clojure)": {
        "endpoint": "http://clj-rdfa.herokuapp.com/extract.ttl?url=",
        "doap": "https://github.com/niklasl/clj-rdfa",
        "doap_url": "/earl-reports/clj-rdfa-doap.ttl"
      },
      "EasyRdf (PHP)": {
        "endpoint": "http://www.easyrdf.org/converter?input_format=rdfa&raw=1&uri=",
        "doap": "http://www.aelius.com/njh/easyrdf/",
        "doap_url": "/earl-reports/easyrdf-doap.ttl"
      },
      "Green Turtle (JavaScript)": {
        "doap": "https://code.google.com/p/green-turtle/",
        "doap_url": "/earl-reports/green-turtle-doap.ttl"
      },
      "java-rdfa (Java)": {
        "endpoint": "http://rdf-in-html.appspot.com/translate/?parser=XHTML&uri=",
        "doap": "https://github.com/shellac/java-rdfa",
        "doap_url": "/earl-reports/java-rdfa-doap.ttl"
      },
      "librdfa (C)": {
        "endpoint": "http://librdfa.digitalbazaar.com/rdfa2rdf.py?uri=",
        "doap": "https://github.com/rdfa/librdfa",
        "doap_url": "/earl-reports/librdfa-doap.ttl"
      },
      "pyRdfa (Python)": {
        "endpoint": "http://www.w3.org/2012/pyRdfa/extract?uri=",
        "doap": "http://www.w3.org/2012/pyRdfa"
      },
      "RDF::RDFa (Ruby)": {
        "endpoint": "http://rdf.greggkellogg.net/distiller?raw=true&in_fmt=rdfa&uri=",
        "doap": "http://rubygems.org/gems/rdf-rdfa",
        "doap_url": "/earl-reports/rdf-rdfa-doap.ttl"
      },
      "RDF::RDFa::Parser (Perl)": {
        "endpoint": "http://buzzword.org.uk/2012/rdfa-distiller/?format=rdfxml&url=",
        "doap": "http://purl.org/NET/cpan-uri/dist/RDF-RDFa-Parser/v_1-097",
        "doap_url": "/earl-reports/rdf-rdfa-parser-doap.ttl"
      },
      "Semargl (Java)": {
        "endpoint": "http://demo.semarglproject.org/process?uri=",
        "doap": "http://semarglproject.org"
      },
      "other":  {
        "endpoint": "",
        "doap": ""
      }
    }
    
The `doap` is the IRI defining the processor. It should be an information resource resulting in a
[DOAP](https://github.com/edumbill/doap/wiki) project description, and will be used when formatting reports.

If the DOAP project description location differs from the identifying IRI, set that location in `doap_url`

## Document caching

Test cases are provided with HTTP ETag headers and expiration values.
Processors _MAY_ cache test case documents but _MUST_ validate the document using HTTP HEAD or conditional GET
operations.

## Crazy Ivan

The test suite is termed _Crazy Ivan_ because of an unusual maneuver popularized in [The Hunt for Red October](http://www.imdb.com/title/tt0099810/quotes?qt=qt0458296)
and [Firefly](http://www.youtube.com/watch?v=Oi6BLxusAM8). It is a term used to detect problems that are hiding, which is what the test suite.

> Seaman Jones: Conn, sonar! Crazy Ivan! 
> Capt. Bart Mancuso: All stop! Quick quiet! [the ships engines are shut down completely] 
> Beaumont: What's goin' on? 
> Seaman Jones: Russian captains sometime turn suddenly to see if anyone's behind them. We call it "Crazy Ivan." The only thing you can do is go dead. Shut everything down and make like a hole in the water. 
> Beaumont: So what's the catch? 
> Seaman Jones: The catch is, a boat this big doesn't exactly stop on a dime... and if we're too close, we'll drift right into the back of him. 

# Contributing

If you would like to contribute a to the website, include an additional
test suite processor endpoint, contribute a new test or to a fix to an existing test,
please follow these steps:

1. Notify the RDFa mailing list, public-rdfa@w3.org ([archives](https://lists.w3.org/Archives/Public/public-rdfa/)),
   that you will be creating a new test or fix and the purpose of the
   change.
2. Clone the git repository: [git://github.com/rdfa/rdfa.github.io.git](https://github.com/rdfa/rdfa.github.io).
3. Make your changes and submit them via github, or via a 'git format-patch'
   to the RDFa mailing list.

Optionally, you can ask for direct access to the repository and may make
changes directly to the RDFa Website source code. All updates to the test 
suite go live within seconds of pushing changes to github via a WebHook call.

## Caution: Cached assets

The JavaScript and CSS files are minimized into cached assets. Any change to CSS or JavaScript files
requires that the assets be re-compiled. This can be done as follows:

    rake assets:precompile

Make sure to do this before committing changes that involve any CSS or JavaScript contained within `file:public/stylesheets` or `public/javascripts`.

# rdfa.info Web Site

The site is built with [Jekyll][] and [Bootstrap][] 3.0. To develop the site
locally, you will also need [Ruby][] and [Bundler][] installed.

To setup the site (after the dependencies are in place), run the following:
```sh
$ bundle install
$ bundle exec jeckyll serve
$ # visit http://localhost:4000/ to test
```

# License

Per-W3C Policy, the RDFa Test Suite is covered by the dual-licensing approach
([BSD-3-Clause](https://spdx.org/licenses/BSD-3-Clause) & W3C Test Suite License) described in
[Licenses for W3C Test Suites](https://www.w3.org/Consortium/Legal/2008/04-testsuite-copyright.html).

All other content in this source repository, unless otherwise noted, is released under
a public domain dedication. This includes all HTML, CSS, and JavaScript used
within the Web site.

At this point in time, the only exception to the public domain
dedication are the icons used on the site, which are copyright by [Glyphicons](https://glyphicons.com/)
and are released under the [CC-BY-SA-3.0](https://creativecommons.org/licenses/by-sa/3.0/) license.


[N-Triples]:    http://www.w3.org/TR/n-triples/
[Turtle]:       http://www.w3.org/TR/2012/WD-turtle-20120710/
[Backbone.js]:  http://documentcloud.github.com/backbone/
[Bootstrap.js]: https://getbootstrap.com/docs/3.3/
[Jekyll]:       https://jekyllrb.com/
[Ruby]:         https://www.ruby-lang.org/
[Bundler]:      https://bundler.io/
