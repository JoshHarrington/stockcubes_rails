/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


import $ from 'jquery'
global.$ = $
global.jQuery = $

import '../functions/general';
import '../functions/alert';

//// will need to include jquery ui - sortable to get sorting to work
import '../functions/cupboard';
import '../functions/list_block';
import '../functions/navigation';
import '../functions/vendor/selectize.min.js';
import '../functions/stocks';
import '../functions/portions';
import '../functions/recipes';
import '../functions/shopping_list';
import '../functions/cupboard_share';
import '../functions/user';
import '../functions/feedback';
import '../functions/dashboard';