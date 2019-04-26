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
        p browser.div(:id=>"package-buildstatus").children
        browser.div(:id=>"package-buildstatus").element(:tag_name => 'td', :class => /^status_\w+\sbuildstatus\snowrap$/).wait_until(timeout: 5) do |i|
          p i.element(:tag_name => 'a').attribute_value('href')
          i.element(:tag_name => 'a').attribute_value('href').size > 5
        end

        doc = Nokogiri::HTML(browser.html).css('#package-buildstatus')

        repos = doc.xpath('//td[contains(@class,"no_border_bottom")]/a')
        archs = doc.xpath('//td[@class="arch"]/div')
        p archs
        build = doc.xpath('//td[contains(@class,"buildstatus")]/a')

        packages = []

        repos.each_with_index do |k, idx|
          packages << {"repo_uri": "https://build.opensuse.org" + k['href'].strip, "repo": k.text, "arch": archs[idx].text.strip, "buildlog": "https://build.opensuse.org" + build[idx]['href'].strip, "buildstatus": build[idx].text}
        end

        packages
      end
    end
  end
end
