// Rails 8 application JavaScript with ActionCable support
//= require_self
//= require_tree ./channels

// Initialize Action Cable consumer - ActionCable is loaded via CDN in layout
(function() {
  // Wait for ActionCable to be available from CDN
  function initializeActionCable() {
    if (typeof ActionCable !== 'undefined') {
      this.App || (this.App = {});
      App.cable = ActionCable.createConsumer('/cable');
      console.log('ActionCable consumer initialized');
    } else {
      // Retry after a short delay if ActionCable isn't loaded yet
      setTimeout(initializeActionCable, 100);
    }
  }
  
  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeActionCable);
  } else {
    initializeActionCable();
  }
})();