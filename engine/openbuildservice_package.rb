require 'watir'

module Onebox
  module Engine
    class OpensuseBuildServiceOnebox
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

        browser = Watir::Browser.new(:chrome, {:chromeOptions => {:args => ['--headless', '--window-size=1200x600']}})
        browser.goto('https://build.opensuse.org/package/show/home:MargueriteSu:branches:devel:languages:ruby:extensions/rubygem-libv8')
        browser.image(:id => "result_reload__0").click

        doc = Nokogiri::HTML(browser.html).css('#package-buildstatus')

        elements = doc.xpath('//div[@id="package-buildstatus"]/table/tbody/tr')
        p elements
        packages = []

        elements.each do |element|
          p element
          repo = element.xpath('//td[contains(@class, "no_border_bottom")]/a')
          arch = element.xpath('//td[@class="arch"]/div')
          build = element.xpath('//td[contains(@class, "buildstatus")]/a')
          p repo
          p arch
          p build
          packages << {"repo_uri": "https://build.opensuse.org" + repo['href'].strip, "repo": repo.text, "arch": arch.text.strip, "buildlog": "https://build.opensuse.org" + build['href'].strip, "buildstatus": build.text}
        end

        packages
      end
    end
  end
end
