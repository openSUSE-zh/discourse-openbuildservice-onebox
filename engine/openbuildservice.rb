module Onebox
  module Engine
    class OpenBuildServiceOnebox
      include Engine
      include LayoutSupport
      include HTML
      always_https

      matches_regexp(%r{^(https?://)?build\.opensuse\.org/\w+/show/(.)+$})

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
          link.gsub(/^.*show\//, '')
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

      def author_link
        'https://build.opensuse.org' + raw.css('.clean_list li a').first['href']
      end

      def author_avatar
        author_html = Nokogiri::HTML(open(author_link))
        author_html.css('.home-avatar').attr('src')
      end

      def fuzzy_time
        raw.css('.clean_list li span.fuzzy-time')[0].text
      end

      def request
        return unless request?

        [{
          "author_link": author_link,
          "author_name": File.basename(author_link),
          "fuzzy_time": fuzzy_time
        }]
      end

      def package
        return unless package?

        browser = Watir::Browser.new(:chrome, {:chromeOptions => {:args => ['--headless', '--window-size=1200x600', '--no-sandbox', '--disable-dev-shm-usage']}})
        browser.goto(link)
        browser.image(:id => "result_reload__0").click

        doc = Nokogiri::HTML(browser.html).css('#package-buildstatus')

        elements = doc.xpath('//div[@id="package-buildstatus"]/table/tbody/tr')
        packages = []
        elements.each do |element|
          repo = element.css(".no_border_bottom a")
          arch = element.css(".arch div")
          build = element.css(".buildstatus a")
          repo_uri = repo.empty? ? "" : "https://build.opensuse.org" + repo.attr('href').text.strip
          repo_text = repo.empty? ? "" : repo.text
          status_class = if build.text == "unresolvable" || build.text == "failed"
                           "obs-status-red"
                         elsif build.text == "succeeded"
                           "obs-status-green"
                         else
                           "obs-status-grey"
                         end
          packages << {"repo_uri": repo_uri, "repo": repo_text, "arch": arch.text.strip, "buildlog": "https://build.opensuse.org" + build.attr('href').text.strip, "status_class": status_class, "buildstatus": build.text}
        end

        packages
      end
    end
  end
end
