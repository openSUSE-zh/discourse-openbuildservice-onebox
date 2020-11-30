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
    new_uri = uri.dup
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

  def buildresults
    result = Array.new
    @repositories.each do |repository|
      target = repository['data-repository']
      arch = repository.css(".repository-state").text().strip!
      state = repository.css(".build-state").text().strip!
      buildlog = repository.css(".build-state a").first["href"]
      if buildlog.start_with?("javascript")
        buildlog = ""
      end
      target_url = buildlog.gsub(/^.*live_build_log/,"/package/binaries").gsub(/\/[^\/]+$/,"")
      result << {"target": target, "url": target_url, "arch": arch, "state": state, "buildlog": buildlog}
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

      matches_regexp(%r{^#{Regexp.union(*SiteSetting.openbuildservice_onebox_instances.split(','))}/\w+/show/(.)+$})

      private

      def host
        uri = @uri.dup
        uri.path = ""
        uri.to_s
      end

      def data
        {
          favicon: host + raw.xpath('//link[@rel="shortcut icon"]').first['href'],
          image: avatar,
          link: @url,
          title: raw.xpath('//title').first.text,
          description: @url =~ %r{/users/} ? raw.css('#home-username').text : raw.css('#description-text').text,
          request: request,
          package: @url =~ %r{/request|package/},
          packages: buildresults,
          buildresults: buildresults.map {|i| i["buildresult"]},
        }
      end

      def avatar
        if @url =~ %r{/request/}
          Nokogiri::HTML(open(host + raw.css('.clean_list li a').first['href'])).css('.home-avatar').attr('src')
        elsif @url =~ %r{/users/}
          raw.css('.home-avatar').attr('src')
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

      def buildresults
        return unless @url =~ %r{/request|package/}
        results = Array.new
        OpenBuildServiceBuildStatus.new(@uri).buildresults.each do |result|
          state = case result[:state]
                  when 'unresolvable','failed', 'broken'
                    'openbuildservice-build-state-failed'
                  when 'succeeded'
                    'openbuildservice-build-state-succeeded'
                  when 'blocked'
                    'openbuildservice-build-state-blocked'
                  when 'scheduled'
                    'openbuildservice-build-state-scheduled'
                  when 'building'
                    'openbuildservice-build-state-building'
                  else
                    'openbuildservice-build-state-disabled'
                  end
          if results.map {|i| i[:repo]}.include?(result[:target])
            results.each do |j|
              if j[:repo] == result[:target]
                j[:buildresult] << {"arch": result[:arch], "buildlog": host + result[:buildlog], "state_class": state, "state": result[:state]}
              end
            end
          else
            results << {"repo": result[:target], "repo_uri": host + result[:url], "buildresult": [{"arch": result[:arch], "buildlog": host + result[:buildlog], "state_class": state, "state": result[:state]}]}
          end
        end
        results
      end
    end
  end
end
