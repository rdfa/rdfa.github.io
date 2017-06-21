var DetailsView = Backbone.View.extend({
  template: _.template($('#details-template').html()),

  attributes: {
    "class":        "row alert alert-info alert-dismissible fade in"
  },

  // Open linkes in a new window/tab
  events: {
    "click a.window": "openWindow"
  },
  
  openWindow: function(event) {
    window.open($(event.target).attr('href'));
    return false;
  },

  render: function () {
    var that = this;
    if (this.model.error) {
      this.$el.text(this.model.error);
    } else {
      this.$el.html(this.template(this.model)).alert();
      this.$(".docUrl a").attr('href', this.model.docUrl);
      this.$(".extractedUrl a").attr('href', this.model.extractedUrl);
      this.$(".sparqlUrl a").attr('href', this.model.sparqlUrl);
    }
    return this;
  }
});
