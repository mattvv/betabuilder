require 'fileutils'

module BetaBuilder
  module DeploymentStrategies
    class Web < Strategy
      def extended_configuration_for_strategy
        proc do
          def deployment_url
            File.join(deploy_to, ipa_name.gsub(" ",""))
          end

          def manifest_url
            File.join(deploy_to, "manifest.plist")
          end

          def display_url
            File.join(deploy_to, display_image)
          end

          def remote_installation_path
            path = File.join(remote_directory)
            if path.match(/\s/)
              FileUtils.mv(path, path.gsub(" ",""))
              path.gsub!(" ","")
            end
            path
          end
        end
      end
      
      def prepare
        plist = CFPropertyList::List.new(:file => "pkg/Payload/#{@configuration.app_name}.app/Info.plist")
        plist_data = CFPropertyList.native_types(plist.value)
        File.open("pkg/dist/manifest.plist", "w") do |io|
          io << %{
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
              <key>items</key>
              <array>
                <dict>
                  <key>URL</key>
                  <string>#{@configuration.deployment_url}</string>
                  <key>display-image</key>
                  <string>#{@configuration.display_url}</string>
                  <key>bundle-identifier</key>
                  <string>#{plist_data['CFBundleIdentifier']}</string>
                  <key>bundle-version</key>
                  <string>#{plist_data['CFBundleVersion']}</string>
                  <key>title</key>
                  <string>#{plist_data['CFBundleDisplayName']}</string>
                </dict>
              </array>
            </dict>
            </plist>
          }
        end
        File.open("pkg/dist/index.html", "w") do |io|
          io << %{
            <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
            <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
            <title>Beta Download</title>
            <style type="text/css">
            body {background:#fff;margin:0;padding:0;font-family:arial,helvetica,sans-serif;text-align:center;padding:10px;color:#333;font-size:16px;}
            #container {width:300px;margin:0 auto;}
            h1 {margin:0;padding:0;font-size:14px;}
            p {font-size:13px;}
            .link {background:#ecf5ff;border-top:1px solid #fff;border:1px solid #dfebf8;margin-top:.5em;padding:.3em;}
            .link a {text-decoration:none;font-size:15px;display:block;color:#069;}
            </style>
            </head>
            <body>
            <div id="container">
            <div class="link"><a href="itms-services://?action=download-manifest&url=#{@configuration.manifest_url}">Tap Here to Install<br />#{@configuration.target}<br />On Your Device</a></div>
            <p><strong>Link didn't work?</strong><br />
            Make sure you're visiting this page on your device, not your computer.</p>
            </body>
            </html>
          }
        end
      end
      
      def deploy
        FileUtils.cp("pkg/Payload/#{@configuration.app_name}.app/#{@configuration.display_image}", "pkg/dist/#{@configuration.display_image}")
        system("scp pkg/dist/* #{@configuration.remote_host}:#{@configuration.remote_installation_path}")
      end
    end
  end
end
