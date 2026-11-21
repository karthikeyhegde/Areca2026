// Start rails-ujs (remote: true links/forms, data-confirm, data-method),
// Turbolinks and Active Storage. Imported right after jquery_global.js so that
// an error in a later import can't stop these from starting.
//
// Webpack 5 loads the ES-module builds of @rails/ujs and @rails/activestorage,
// so use import (require("@rails/ujs") returns { default: Rails } and has no .start).
import Rails from '@rails/ujs'
import Turbolinks from 'turbolinks'
import * as ActiveStorage from '@rails/activestorage'

if (!window._rails_loaded) Rails.start()
Turbolinks.start()
ActiveStorage.start()
