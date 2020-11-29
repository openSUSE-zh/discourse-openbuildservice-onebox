# name: openbuildservice-onebox
# about: OneBox preview for Open Build Service
# version: 2.0.0
# authors: Marguerite Su <marguerite@opensuse.org>
# url: https://github.com/openSUSE-zh/discourse-openbuildservice-onebox

enabled_site_setting :openbuildservice_onebox_enabled

after_initialize do
  register_asset 'stylesheets/openbuildservice.scss'
  require 'net/http'
  require 'uri'
  require 'nokogiri'
  require_dependency 'site_setting'
  require_relative 'engine/openbuildservice_onebox'
  Onebox.options.load_paths.push(File.join(File.dirname(__FILE__), "templates"))
end
