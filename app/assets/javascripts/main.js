//global js goes in here

(function () {
	/**
	 * main.js = global
	 */
	var module = {};

	/**
	 * Global init code for the whole application
	 */
	module.init = function () {

	};

	/**
	 * Initialize the app and run the bootstrapper
	 */
	$(document).ready(function () {
		module.init();
		HBS.initPage();
	});

	HBS.namespace('UMS.main', module);
}());
