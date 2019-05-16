require_dependency 'site_setting'

module Onebox
  module Engine
    class OpenBuildServiceOnebox
      include Engine
      include LayoutSupport
      include HTML
      always_https

      matches_regexp(%r{^(https?://)?#{Regexp.union(*whitelist)}/\w+/show/(.)+$})

      private

      def data
        {
          image: avatar,
          link: link,
          title: title,
          description: user? ? raw.css('#home-username').text : raw.css('#description-text').text,
          request: request,
          packages: package
        }
      end

      def whitelist
        SiteSetting.open_build_service_instance.split(',').map { |i| Regexp.escape(URI.parse(i).host) }
      end

      def avatar
        if request?
          author_avatar
        elsif user?
          raw.css('.home-avatar').attr('src')
        end
      end

      def title
        if user?
          raw.css('#home-realname').text
        else
          link.gsub(%r{^.*show/}, '')
        end
      end

      def user?
        link =~ %r{/user/}
      end

      def request?
        link =~ %r{/request/}
      end

      def package?
        link =~ %r{/package/}
      end

      def host
        'https://' + URI.parse(link).host
      end

      def author_link
        host + raw.css('.clean_list li a').first['href']
      end

      def author_avatar
        author_html = Nokogiri::HTML(open(author_link))
        author_html.css('.home-avatar').attr('src')
      end

      def request
        return unless request?

        [{
          "author_link": author_link,
          "author_name": File.basename(author_link),
          "fuzzy_time": raw.css('.clean_list li span.fuzzy-time')[0].text,
          "request_state": raw.css('.clean_list li a')[1].text,
          "source_prj_link": host + raw.css('a.project')[0].attr('href'),
          "source_prj": raw.css('a.project')[0].text,
          "source_pkg_link": host + raw.css('a.package')[0].attr('href'),
          "source_pkg": raw.css('a.package')[0].text,
          "dest_prj_link": host + raw.css('a.project')[1].attr('href'),
          "dest_prj": raw.css('a.project')[1].text,
          "dest_pkg_link": host + raw.css('a.package')[1].attr('href'),
          "dest_pkg": raw.css('a.package')[1].text
        }]
      end

      def package
        reload_id = if request?
                      'result_reload_0_0'
                    elsif package?
                      'result_reload__0'
                    end
        return unless reload_id

        buildstatus(reload_id)
      end

      def buildstatus(reload_id)
        browser = Watir::Browser.new(:chrome, chromeOptions: { args: ['--headless', '--window-size=1200x600', '--no-sandbox', '--disable-dev-shm-usage'] })
        browser.goto(link)
        browser.image(id: reload_id).click

        doc = Nokogiri::HTML(browser.html).css('#package-buildstatus')

        elements = doc.xpath('//div[@id="package-buildstatus"]/table/tbody/tr')
        packages = []
        elements.each do |element|
          repo = element.css('.no_border_bottom a')
          arch = element.css('.arch div')
          build = element.css('.buildstatus a')
          repo_uri = repo.empty? ? '' : host + repo.attr('href').text.strip
          repo_text = repo.empty? ? '' : repo.text
          status_class = if build.text == 'unresolvable' || build.text == 'failed'
                           'obs-status-red'
                         elsif build.text == 'succeeded'
                           'obs-status-green'
                         else
                           'obs-status-grey'
                         end
          packages << { "repo_uri": repo_uri, "repo": repo_text, "arch": arch.text.strip, "buildlog": host + build.attr('href').text.strip, "status_class": status_class, "buildstatus": build.text }
        end

        packages
      end
    end
  end
end
