# name: openbuildservice-onebox
# about: OneBox preview for Open Build Service
# version: 1.0.0
# authors: Marguerite Su <marguerite@opensuse.org>
# url: https://github.com/openSUSE-zh/discourse-openbuildservice-onebox

require_relative 'engine/openbuildservice_package_onebox'

enabled_site_setting :open_build_service_instance

register_asset 'stylesheets/openbuildservice.scss'

Onebox.options.load_paths.push(File.join(File.dirname(__FILE__), "templates"))
