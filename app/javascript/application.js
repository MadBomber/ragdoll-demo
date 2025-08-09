// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// ActionCable integration
import { createConsumer } from "@rails/actioncable"

// Initialize ActionCable consumer with proper global setup
(function() {
  window.App = window.App || {}
  if (!window.App.cable) {
    window.App.cable = createConsumer()
    console.log("ActionCable consumer initialized from importmap:", window.App.cable)
  }
})()

console.log("Rails 8 application.js loaded with Turbo and Stimulus")