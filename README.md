## Discourse Open Build Service Onebox

This plugin adds [Onebox](https://github.com/discourse/onebox) support for [Open Build Service](https://openbuildservice.org) to [Discourse](https://discourse.org).

Open Build Service is a build automation project developed and used by openSUSE and Packman.

## Supported

* Package
* Project
* User
* Request

## Installation

Follow this official [plugin installation how-to](https://meta.discourse.org/t/install-a-plugin/19157).

## Troubleshooting

If a gem for this plugin can't be installed via `bundle exec rake db:migrate` automatically. You can try this command:

    gem install ffi -v 1.10.0 -i /srv/www/vhosts/discourse/plugins/discourse-openbuildservice-onebox/gems/2.6.3 --no-document --ignore-dependencies --no-user-install

## License

MIT
