# name: openbuildservice-onebox
# about: OneBox preview for Open Build Service
# version: 1.0.0
# authors: Marguerite Su <marguerite@opensuse.org>
# url: https://github.com/openSUSE-zh/discourse-openbuildservice-onebox

gem 'watir','6.16.5'
gem 'selenium-webdriver','~> 3.6'

enabled_site_setting :open_build_service_instance

register_asset 'stylesheets/openbuildservice.scss'

require 'uri'
require_relative 'engine/openbuildservice_onebox'

Onebox.options.load_paths.push(File.join(File.dirname(__FILE__), "templates"))
