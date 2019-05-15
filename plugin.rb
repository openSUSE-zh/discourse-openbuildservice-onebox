# name: openbuildservice-onebox
# about: OneBox preview for Open Build Service
# version: 1.0.0
# authors: Marguerite Su <marguerite@opensuse.org>
# url: https://github.com/openSUSE-zh/discourse-openbuildservice-onebox


gem 'regexp_parser','1.3.0'
gem 'ffi','1.10.0'
gem 'childprocess', '0.6.3'
gem 'rubyzip', '1.2.2'
gem 'selenium-webdriver', '3.141.0'
gem 'watir', '6.16.5'

register_asset 'stylesheets/openbuildservice.scss'

require 'uri'
require 'watir'
require_relative 'engine/openbuildservice_onebox'

Onebox.options.load_paths.push(File.join(File.dirname(__FILE__), "templates"))
