## 0.2.7 (5 February 2011)

  - Updated to use jQuery 1.5 by default

## 0.2.6 (1 December 2010)

Feature:

  - Updated to use jQuery 1.4.4 by default

## 0.2.5 (4 November 2010)

Bugfix:

  - Download JQuery Rails UJS via HTTPS since Github is now HTTPS only

## 0.2.4 (16 October 2010)

Features:

  - Updated to use the new jQuery 1.4.3 by default, with the IE .live() bug fixed
  - Always download the newest 1.x release of jQuery UI
  - Try to install unknown versions of jQuery, with fallback to the default
  - Print informative messages in the correct Generator style

## 0.2.3 (13 October 2010)

Features:

  - Support Edge Rails 3.1 by depending on Rails ~>3.0
  - Add Sam Ruby's assert_select_jquery test helper method
  - Use jquery.min only in production (and not in the test env)

## 0.2.2 (8 October 2010)

Feature:

  - Depend on Rails >=3.0 && <4.0 for edge Rails compatibility

## 0.2.1 (2 October 2010)

Bugfix:

  - Default to jQuery 1.4.1 as recommended by jQuery-ujs
    due to a bug in 1.4.2 (http://jsbin.com/uboxu3/7/)

## 0.2 (2 October 2010)

Features:

  - Allow specifying which version of jQuery to install
  - Add generator tests (thanks, Louis T.)
  - Automatically use non-minified JS in development mode

## 0.1.3 (16 September 2010)

Bugfix:

  - allow javascript :defaults tag to be overridden

## 0.1.2 (18 August 2010)

Bugfix:

  - check for jQueryUI in the right place

## 0.1.1 (16 August 2010)

Bugfix:

  - fix generator by resolving namespace conflict between Jquery::Rails and ::Rails