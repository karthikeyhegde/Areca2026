// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

// Order matters: imports run top to bottom, before the rest of this file.
import '../setup/jquery_global'   // window.$ / window.jQuery for inline view scripts
import 'channels'


import '../setup/select2'
import 'select2/dist/css/select2.css';

import '../stylesheets/application.scss'
import '../../../app/assets/stylesheets/application.css'
import '../../../app/assets/javascripts/application.js'
import '../../../app/assets/javascripts/Chart.min.js'
import './custom'
import "bootstrap"
import "@fortawesome/fontawesome-free/js/all";


import 'webpack-jquery-ui/css'
import 'webpack-jquery-ui' // if you need only sortable widget.

// Must come AFTER bootstrap: rails-ujs stops the click event on remote: true
// links, so Bootstrap's data-toggle="modal" handler only runs if it was
// registered first (New/List popups use both on the same link).
import '../setup/rails_start'     // rails-ujs (remote: true), Turbolinks, Active Storage



// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//

 


function PrintElem(elem)
{
    var mywindow = window.open('', 'PRINT', 'height=400,width=600');

    mywindow.document.write('<html><head><title>' + document.title  + '</title>');
    mywindow.document.write('</head><body >');
    mywindow.document.write('<h1>' + document.title  + '</h1>');
    mywindow.document.write(document.getElementById('balance_div').outerHTML)
    mywindow.document.write(document.getElementById('user_balance_table').innerHTML);
    mywindow.document.write('</body></html>');

    mywindow.document.close(); // necessary for IE >= 10
    mywindow.focus(); // necessary for IE >= 10*/

    mywindow.print();
    mywindow.close();

    return true;
}

