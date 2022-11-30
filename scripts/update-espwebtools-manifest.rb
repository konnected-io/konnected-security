require 'uri'
require 'net/http'
require 'json'

uri = URI('https://install.konnected.io/manifest.json')
req = Net::HTTP::Get.new(uri)
res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(req)
end

manifest = JSON.parse(res.body)
build = manifest['builds'].detect{|b| b['chipFamily'] == ENV['CHIP_FAMILY']}
build['parts'] = { path: ENV['RELEASE_IMAGE_URI'], offset: 0 }
File.write('manifest.json', JSON.dump(manifest))