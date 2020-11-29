class OpenBuildServiceBuildStatus
  def initialize(uri)
    resp = Net::HTTP.get_response(uri)
    cookie = resp['Set-Cookie']

    doc = Nokogiri::HTML(resp.body)

    token = doc.at("meta[name='csrf-token']")['content']
    path = doc.at("div[id='buildresult-urls']")['data-buildresult-url']
    index = doc.at("ul[id='buildresult-box']")['data-index']
    package = doc.at("ul[id='buildresult-box']")['data-package']
    project = doc.at("ul[id='buildresult-box']")['data-project']

    query = Hash["index"=>index,"package"=>package,"project"=>project,"show_all"=>false]
    new_uri = uri
    new_uri.path = path
    new_uri.query = URI.encode_www_form(query)

    http = Net::HTTP.new(new_uri.host, new_uri.port)
    http.use_ssl = new_uri.scheme == 'https'
    request = Net::HTTP::Get.new(new_uri)
    request['Cookie'] = cookie
    request['X-Requested-With'] = 'XMLHttpRequest'
    request['X-CSRF-Token'] = token
    request['Referer'] = uri.to_s
    request['User-Agent'] = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.111 Safari/537.36'

    response = http.request(request)

    new_doc = Nokogiri::HTML(response.body)

    buildstatus = new_doc.at("div[id='package-buildstatus']")
    @repositories = buildstatus.css("div[class*='show']")
  end

  def buildresult
    result = Array.new
    @repositories.each do |repository|
      target = repository['data-repository']
      arch = repository.css(".repository-state").text().strip!
      state = repository.css(".build-state").text().strip!
      buildlog = repository.css(".build-state a").first["href"]
      target_url = buildlog.gsub(/^.*live_build_log/,"/package/binaries").gsub(/\/[^\/]+$/,"")
      result << {"target": target, "target_url": target_url, "arch": arch, "state": state, "buildlog": buildlog}
    end
    result
  end
end

module Onebox
  module Engine
    class OpenBuildServiceOnebox
      include Engine
      include LayoutSupport
      include HTML
      always_https

      matches_regexp(%r{^#{Regexp.union(*SiteSetting.openbuildservice_onebox_instances.split(',').map { |i| Regexp.escape(i) }
)}/\w+/show/(.)+$})

      private

      def host
        uri = @uri
        uri.path = ""
        uri.to_s + "/"
      end

      def data
        {
          image: avatar,
          link: @url,
          title: title,
          description: @url =~ %r{/user/} ? raw.css('#home-username').text : raw.css('#description-text').text,
          request: request,
          packages: package
        }
      end

      def avatar
        if @url =~ %r{/request/}
          Nokogiri::HTML(open(host + raw.css('.clean_list li a').first['href'])).css('.home-avatar').attr('src')
        elsif @url =~ %r{/user/}
          raw.css('.home-avatar').attr('src')
        end
      end

      def title
        if @url =~ %r{/user/}
          raw.css('#home-realname').text
        else
          link.gsub(%r{^.*show/}, '')
        end
      end

      def request
        return unless @url =~ %r{/request/}
        author_link = host + raw.css('.clean_list li a').first['href']
        [{
          "author_link": author_link,
          "author_name": File.basename(author_link),
          "fuzzy_time": raw.css('.clean_list li span.fuzzy-time').first.text,
          "request_state": raw.css('.clean_list li a')[1].text,
          "source_prj_link": host + raw.css('a.project').first['href'],
          "source_prj": raw.css('a.project').first.text,
          "source_pkg_link": host + raw.css('a.package').first['href'],
          "source_pkg": raw.css('a.package').first.text,
          "dest_prj_link": host + raw.css('a.project')[1]['href'],
          "dest_prj": raw.css('a.project')[1].text,
          "dest_pkg_link": host + raw.css('a.package')[1]['href'],
          "dest_pkg": raw.css('a.package')[1].text
        }]
      end

      def package
        return unless @url =~ %r{/request|package/}
        packages = Array.new
        OpenBuildServiceBuildStatus.new(@uri).buildresult.each do |result|
          state = if result["state"] == 'unresolvable' || result["state"] == 'failed'
                           'obs-status-red'
                         elsif result["state"] == 'succeeded'
                           'obs-status-green'
                         else
                           'obs-status-grey'
                         end
          packages << { "repo_uri": host + result["target_url"], "repo": result["target"], "arch": result["arch"], "buildlog": host + result["buildlog"], "state_class": state, "buildstatus": result["state"] }
        end
        packages
      end
    end
  end
end
