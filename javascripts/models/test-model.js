/*global Backbone, $, $rdf */
// Test model, ID is combination of version, hostLanguage and num
window.Test = Backbone.Model.extend({
  // Calls back with retrieved source
  source: function (cb) {
    var entries = [];
    var hostLanguages = this.get('hostLanguages');
    var versions = this.get('versions');
    var num = this.get('num');

    versions.forEach(function (version) {
      hostLanguages.forEach(function (lang) {
        var suffix = {
          xhtml1: "xhtml",
          xhtml5: "xhtml",
          html4:  "html",
          html5:  "html",
          svg:    "svg",
          xml:    "xml"
        }[lang];

        if (version === 'rdfa1.0' && ['html5', 'xhtml5'].includes(lang)) {
        // RDFa 1.0 not defined for HTML5
        } else {
          entries.push({
            num: num,
            doc_uri: "test-cases/" + version + "/" + lang + "/" + num + "." + suffix,
            version_lang: version + '+' + lang});
        }
      });
    });
    cb(entries);
  },

  // A URL to the test server
  url: function (path) {
    var u = location.protocol + "//" + location.hostname;
    if (!["", "80", "443"].includes(location.port)) { u += ":" + location.port;}
    return (u + path);
  },

  // Get the URL for the test file
  testUrl: function () {
    var suffix = {
      xhtml1: "xhtml",
      xhtml5: "xhtml",
      html4:  "html",
      html5:  "html",
      svg:    "svg",
      xml:    "xml"
    }[this.get('hostLanguage')];

    // FIXME: Use our base URL.
    return '/test-suite/test-cases' +
      '/' + this.get('version') +
      '/' + this.get('hostLanguage') +
      '/' + this.get('num') +
      '.' + suffix;
  },

  // Get the URL for the extracted RDF from the test file
  extractedUrl: function () {
    return this.processorURL() + this.url(this.testUrl());
  },

  // Get the URL for the SPARQL file
  sparqlUrl: function () {
    return '/test-suite/test-cases' +
      '/' + this.get('version') +
      '/' + this.get('hostLanguage') +
      '/' + this.get('num') +
      '.sparql';
  },
  
  // Get the URL for the reference file
  referenceUrl: function () {
    return '/test-suite/test-cases' +
      '/' + this.get('version') +
      '/' + this.get('hostLanguage') +
      '/' + this.get('num') +
      '.ttl';
  },

  // Get the details for a given test
  details: function (cb) {
    // Retrieve results from processor and canonical representation
    var testUrl = this.testUrl();
    var referenceUrl = this.referenceUrl();
    var extractedUrl = this.extractedUrl();
    var sparqlUrl = this.sparqlUrl();
    var res = {
      num:          this.get('num'),
      purpose:      this.get('purpose'),
      docUrl:       testUrl,
      referenceText:"unloaded",
      docText:      "unloaded",
      extractedUrl: extractedUrl,
      extractedText:"unloaded",
      sparqlUrl:    sparqlUrl,
      sparqlText:   "unloaded"
    };

    $.ajax({
      url: testUrl,
      dataType: 'text'
     }).then(function(docText) {
       res.docText = docText;
       return $.ajax({url: referenceUrl, dataType: 'text'});
     }).then(function(referenceText) {
       res.referenceText = referenceText;
       return $.ajax({url: sparqlUrl, dataType: 'text'});
     }).then(function(sparqlText) {
       res.sparqlText = sparqlText;
       return $.ajax({url: extractedUrl, dataType: 'text'});
     }).then(function(extractedText) {
       res.extractedText = extractedText;
       cb(res);
     }).fail(function (xhr) {
       // Indicate fail and style
       res.extractedText = "Failed to load: " + xhr.status + ' ' + xhr.statusText;
       cb(res);
    });
  },

  // Run the test, causes this.result to be set
  run: function () {
    var that = this,
        kb = $rdf.graph(),
        sparqlUrl = this.sparqlUrl(),
        extractedUrl = this.extractedUrl(),
        base = this.testURI(),
        expectedResults = this.get("expectedResults");

    this.set("result", "running");

    // Fetch SPARQL
    $.ajax({url: extractedUrl, dataType: 'text'})
     .always(function (extractedText, status, xhr) {
       if (status === "error") {
         window.console && window.console.log("Error fetching " + extractedUrl);
         that.set("result", "error");
         return;
       }
       var ct = xhr.getResponseHeader("content-type").split(";")[0];
       if (xhr.status !== 200) {extractedText = "";}
       try {
         $rdf.parse(extractedText, kb, base, ct);
       } catch (parseErr) {
         // Indicate fail and style
         window.console && window.console.log("Parse error: " + parseErr);
         that.set("result", "error");
         return;
       }

       $.ajax({url: sparqlUrl, dataType: 'text'})
        .then(function(sparqlText) {
          // Parse SPARQL
          var query = $rdf.SPARQLToQuery(sparqlText, true, kb);
          var queryResult = "error";
          if (query) {
            queryResult = expectedResults ? "FAIL" : "PASS";
            kb.fetcher = null; // disables resource fetching
            kb.query(query, function (result) {
              // Result callback
              // Indicate pass/fail and style
              queryResult = result === expectedResults ? "PASS" : "FAIL";
            });
          }
          // Indicate fail and style
          that.set("result", queryResult);
        }).fail(function (result) {
          // Indicate fail and style
          window.console && window.console.log("Error fetching " + sparqlUrl);
          that.set("result", "error");
        });
    });
  },
  
  // Return the selected processor URI
  // This is set when the hostLanguage is selected on all selected test divs
  // The processorURL is updated with query parameters from the test-case object.
  // Reset test to original condition
  processorURL: function() {
    var url = this.get('processorURL');
    var queryParam = this.get('queryParam');

    if (queryParam) {
      // Add any parameter to the processorURL
      url = url.replace(/([\?&])([^\?&]*)$/, "$1" + queryParam + "&$2");
    }
    return url;
  },

  // Test URI
  testURI: function() {
    return "http://rdfa.info/test-suite/test-cases" +
    '/' + this.get('version') +
    '/' + this.get('hostLanguage') +
    '/manifest#' + this.get('num');
  },

  reset: function () {
    this.result = this.source = this.details = null;
  }
});

// Collection of defined tests, ordered by test number.
// There is a different collection of tests for each combination of version and host language
window.TestCollection = Backbone.Collection.extend({
  model:  Test,
  
  url:    '/data/manifest.jsonld',
  
  initialize:   function(models, options) {
    if (options) {
      this.version = options.version;
    }
    
    // Bind do our own change event to be notified when tests complete to allow them to
    // chain to the next
    this.bind('change', this.run_next, this);
  },
  
  // Update models based on test options
  filter: function(version) {
    var version = this.version.get('version');
    var hostLanguage = this.version.get('hostLanguage');
    var processorURL = this.version.get('processorURL');

    this.running = null;
    this.passed = this.failed = 0;

    var filteredTests = _.filter(this.loadedData, function(data) {
      return _.include(data.versions, version) &&
             _.include(data.hostLanguages, hostLanguage);
    });
    
    // Reset the collection with filtered tests
    var tests = _.map(filteredTests, function(data) {
      // Add selected version, hostLanguage and processorURL to each test
      return _.extend({
        version: version,
        hostLanguage: hostLanguage,
        processorURL: processorURL
      }, data);
    });

    this.reset(tests);
    return tests;
  },

  // Run the tests, sequence through each test trigging it to run and signal an update
  // event for each test completion.
  run: function() {
    console.log("start running tests");
    this.running = "running";
    this.passed = this.failed = 0;

    // Reset test results
    _.each(this.models, function(test) { test.set('result', null); });
    
    // Run first test
    this.models[0].run();
  },

  // Triggered when a model changes, which causes chaining if we're running tests
  run_next: function(test) {
    var result = test.get('result');

    if (this.running && _.include(["PASS", "FAIL"], result)) {
      console.log("test " + test.get('num') + ' completed with ' + result);
      this.passed = _.reduce(this.models, function(memo, test) {
        return memo + (test.get('result') == "PASS" ? 1 : 0);
      }, 0);
      this.failed = _.reduce(this.models, function(memo, test) {
        return memo + (test.get('result') == "FAIL" ? 1 : 0);
      }, 0);

      var total = this.passed + this.failed;
      var next = this.at(total);
      if (next) {
        console.log("next test: " + next.get('num'));
        next.run();
      } else {
        console.log('tests completed');
        this.running = "completed";
      }
    }
  },

  // Override parse() to deal with JSON-LD array semantics
  // Return all tests
  parse: function(response) {
    this.loadedData = response['@graph'];
    
    // Initialize Host Language Version mappings by inspecting each test
    var map = [];
    _.each(this.loadedData, function(test) {
      _.each(test.versions, function(vers) {
        if (map[vers] == null) { map[vers] = []; }
        _.each(test.hostLanguages, function(hl) {
          var hlUpper = hl.toUpperCase();
          if (_.indexOf(map[vers], hlUpper) === -1) {
            map[vers].push(hlUpper);
          }
        });
      });
    });
    // Hard-code host languages for RDFa 1.0
    map['rdfa1.0'] = ["XHTML1", "XML"];
    this.version.set('versionHostLanguageMap', map);

    // Don't return anything on parse, that is done through filtering
    return this.filter();
  },

  // Order tests by test number
  comparator: function(test) {
    return test.get('num');
  }
});
