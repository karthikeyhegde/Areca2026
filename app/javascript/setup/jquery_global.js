// Expose jQuery globally for inline <script> blocks in the views.
// Imported first by packs/application.js so it runs before anything else.
import $ from 'jquery'

window.jQuery = $
window.$ = $
