import $ from 'jquery'
import select2 from 'select2'

// Webpack loads Select2's CommonJS build as an installer.
if (!$.fn.select2) select2(window, $)
