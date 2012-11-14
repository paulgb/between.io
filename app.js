
/*
 * Between.io is an HTTP debugging proxy.
 * See README.md for details.
 *
 * This is the entry point for both the
 * proxy (which logs the requests/responses)
 * and the web server, but they run in
 * separate processes. A single command-
 * line argument determines which type
 * of process it will be.
 *
 * This is the only JavaScript file that
 * runs on the backend. Everything else
 * is CoffeeScript. We import that here
 * and then delegate to dispatch, which
 * decides which type of process to run.
 */

require('coffee-script')

require('./src/dispatch')

