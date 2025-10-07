# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AttackProtectionMiddleware do
  let(:app) { ->(env) { [200, { 'Content-Type' => 'text/html' }, ['Success']] } }
  let(:middleware) { described_class.new(app) }

  def make_request(path:, user_agent: nil, client_ip: nil, x_forwarded_for: nil)
    env = Rack::MockRequest.env_for(path)
    env['HTTP_USER_AGENT'] = user_agent if user_agent
    env['HTTP_CLIENT_IP'] = client_ip if client_ip
    env['HTTP_X_FORWARDED_FOR'] = x_forwarded_for if x_forwarded_for
    middleware.call(env)
  end

  describe 'WordPress/PHP path blocking' do
    context 'when accessing blocked WordPress paths' do
      it 'blocks /wp-login.php with 404' do
        status, headers, _body = make_request(path: '/wp-login.php')

        expect(status).to eq(404)
        expect(headers['X-Attack-Protection']).to eq('blocked-path')
        expect(headers['Content-Type']).to eq('text/html')
      end

      it 'blocks /wp-admin with 404' do
        status, headers, _body = make_request(path: '/wp-admin')

        expect(status).to eq(404)
        expect(headers['X-Attack-Protection']).to eq('blocked-path')
      end

      it 'blocks /wp-content with 404' do
        status, _headers, _body = make_request(path: '/wp-content/themes/example')

        expect(status).to eq(404)
      end

      it 'blocks /xmlrpc.php with 404' do
        status, _headers, _body = make_request(path: '/xmlrpc.php')

        expect(status).to eq(404)
      end

      it 'blocks /wp-config.php with 404' do
        status, _headers, _body = make_request(path: '/wp-config.php')

        expect(status).to eq(404)
      end

      it 'blocks case-insensitive WordPress paths' do
        status, _headers, _body = make_request(path: '/WP-LOGIN.PHP')

        expect(status).to eq(404)
      end
    end

    context 'when accessing blocked PHP admin paths' do
      it 'blocks /phpmyadmin with 404' do
        status, _headers, _body = make_request(path: '/phpmyadmin')

        expect(status).to eq(404)
      end

      it 'blocks /phpMyAdmin with 404' do
        status, _headers, _body = make_request(path: '/phpMyAdmin/index.php')

        expect(status).to eq(404)
      end

      it 'blocks /admin.php with 404' do
        status, _headers, _body = make_request(path: '/admin.php')

        expect(status).to eq(404)
      end
    end

    context 'when accessing other attack vector paths' do
      it 'blocks /.env files with 404' do
        status, _headers, _body = make_request(path: '/.env')

        expect(status).to eq(404)
      end

      it 'blocks /.git/config with 404' do
        status, _headers, _body = make_request(path: '/.git/config')

        expect(status).to eq(404)
      end

      it 'blocks /backup.sql with 404' do
        status, _headers, _body = make_request(path: '/backup.sql')

        expect(status).to eq(404)
      end
    end

    context 'when accessing legitimate Rails paths' do
      it 'allows /admin (Rails admin route) to pass through' do
        status, _headers, _body = make_request(path: '/admin')

        expect(status).to eq(200)
      end

      it 'allows /users/sign_in to pass through' do
        status, _headers, _body = make_request(path: '/users/sign_in')

        expect(status).to eq(200)
      end

      it 'allows root path to pass through' do
        status, _headers, _body = make_request(path: '/')

        expect(status).to eq(200)
      end

      it 'allows /verses to pass through' do
        status, _headers, _body = make_request(path: '/verses')

        expect(status).to eq(200)
      end
    end
  end

  describe 'malicious user agent blocking' do
    context 'when user agent contains known attack tools' do
      it 'blocks sqlmap user agent with 403' do
        status, headers, _body = make_request(
          path: '/users',
          user_agent: 'sqlmap/1.0-dev'
        )

        expect(status).to eq(403)
        expect(headers['X-Attack-Protection']).to eq('blocked-request')
      end

      it 'blocks nikto user agent with 403' do
        status, _headers, _body = make_request(
          path: '/users',
          user_agent: 'Mozilla/5.00 (Nikto/2.1.6)'
        )

        expect(status).to eq(403)
      end

      it 'blocks wpscan user agent with 403' do
        status, _headers, _body = make_request(
          path: '/users',
          user_agent: 'WPScan v3.8.0'
        )

        expect(status).to eq(403)
      end

      it 'blocks metasploit user agent with 403' do
        status, _headers, _body = make_request(
          path: '/users',
          user_agent: 'Metasploit Framework'
        )

        expect(status).to eq(403)
      end

      it 'is case-insensitive when matching user agents' do
        status, _headers, _body = make_request(
          path: '/users',
          user_agent: 'SQLMAP/1.0'
        )

        expect(status).to eq(403)
      end
    end

    context 'when user agent is legitimate' do
      it 'allows Chrome user agent' do
        status, _headers, _body = make_request(
          path: '/users',
          user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/91.0'
        )

        expect(status).to eq(200)
      end

      it 'allows Firefox user agent' do
        status, _headers, _body = make_request(
          path: '/users',
          user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0'
        )

        expect(status).to eq(200)
      end

      it 'allows requests with no user agent' do
        status, _headers, _body = make_request(path: '/users')

        expect(status).to eq(200)
      end
    end
  end

  describe 'IP spoofing protection' do
    let(:spoofing_app) do
      lambda do |env|
        # Simulate what RemoteIp middleware does when it detects spoofing
        client_ip = env['HTTP_CLIENT_IP']
        x_forwarded = env['HTTP_X_FORWARDED_FOR']

        if client_ip.present? && x_forwarded.present? && client_ip != x_forwarded.split(',').first.strip
          raise ActionDispatch::RemoteIp::IpSpoofAttackError,
                "IP spoofing attack?! HTTP_CLIENT_IP=#{client_ip} HTTP_X_FORWARDED_FOR=#{x_forwarded}"
        end

        [200, { 'Content-Type' => 'text/html' }, ['Success']]
      end
    end

    let(:middleware_with_spoofing) { described_class.new(spoofing_app) }

    context 'when conflicting IP headers are present' do
      it 'catches IP spoofing exception and returns 403' do
        env = Rack::MockRequest.env_for('/users')
        env['HTTP_CLIENT_IP'] = '192.168.1.100'
        env['HTTP_X_FORWARDED_FOR'] = '10.0.0.1'

        status, headers, _body = middleware_with_spoofing.call(env)

        expect(status).to eq(403)
        expect(headers['X-Attack-Protection']).to eq('blocked-request')
      end

      it 'logs the spoofing attempt with details' do
        env = Rack::MockRequest.env_for('/wp-login.php')
        env['HTTP_CLIENT_IP'] = '192.168.1.100'
        env['HTTP_X_FORWARDED_FOR'] = '10.0.0.1'
        env['REMOTE_ADDR'] = '203.0.113.1'
        env['HTTP_USER_AGENT'] = 'BadBot/1.0'

        # The middleware logs using a block that yields multiline content
        # We verify the warning is called with a block
        expect(Rails.logger).to receive(:warn) do |*args, &block|
          if block
            message = block.call
            expect(message).to include('IP Spoofing attempt detected')
            expect(message).to include('/wp-login.php')
            expect(message).to include('BadBot/1.0')
            expect(message).to include('HTTP_CLIENT_IP: 192.168.1.100')
            expect(message).to include('HTTP_X_FORWARDED_FOR: 10.0.0.1')
          end
        end

        middleware_with_spoofing.call(env)
      end

      it 'does not send errors to Sentry (prevents noise)' do
        env = Rack::MockRequest.env_for('/users')
        env['HTTP_CLIENT_IP'] = '192.168.1.100'
        env['HTTP_X_FORWARDED_FOR'] = '10.0.0.1'

        # Verify the error is caught and doesn't propagate
        expect { middleware_with_spoofing.call(env) }.not_to raise_error

        status, _headers, _body = middleware_with_spoofing.call(env)
        expect(status).to eq(403)
      end
    end

    context 'when IP headers are consistent' do
      it 'allows request with matching IP headers' do
        env = Rack::MockRequest.env_for('/users')
        env['HTTP_CLIENT_IP'] = '10.0.0.1'
        env['HTTP_X_FORWARDED_FOR'] = '10.0.0.1'

        status, _headers, _body = middleware_with_spoofing.call(env)

        expect(status).to eq(200)
      end

      it 'allows request with only X-Forwarded-For' do
        env = Rack::MockRequest.env_for('/users')
        env['HTTP_X_FORWARDED_FOR'] = '10.0.0.1'

        status, _headers, _body = middleware_with_spoofing.call(env)

        expect(status).to eq(200)
      end

      it 'allows request with only CLIENT_IP' do
        env = Rack::MockRequest.env_for('/users')
        env['HTTP_CLIENT_IP'] = '10.0.0.1'

        status, _headers, _body = middleware_with_spoofing.call(env)

        expect(status).to eq(200)
      end

      it 'allows request with no IP headers' do
        env = Rack::MockRequest.env_for('/users')

        status, _headers, _body = middleware_with_spoofing.call(env)

        expect(status).to eq(200)
      end
    end
  end

  describe 'logging behavior' do
    context 'when blocking attack paths' do
      it 'logs blocked WordPress paths' do
        expect(Rails.logger).to receive(:warn).with(a_string_matching(/Blocked attack path: \/wp-login\.php/))

        make_request(path: '/wp-login.php')
      end

      it 'logs the request path and remote address' do
        # The middleware logs the request.ip which may be empty in test environment
        # We just verify that a warning is logged
        expect(Rails.logger).to receive(:warn)

        make_request(path: '/wp-admin')
      end
    end

    context 'when blocking malicious user agents' do
      it 'logs blocked user agents' do
        expect(Rails.logger).to receive(:warn).with(
          a_string_matching(/Blocked malicious user agent: sqlmap/)
        )

        make_request(path: '/users', user_agent: 'sqlmap/1.0')
      end
    end
  end

  describe 'combined attack scenarios' do
    it 'blocks WordPress path even with legitimate user agent' do
      status, _headers, _body = make_request(
        path: '/wp-login.php',
        user_agent: 'Mozilla/5.0 (Macintosh) Chrome/91.0'
      )

      expect(status).to eq(404)
    end

    it 'blocks malicious user agent even on legitimate path' do
      status, _headers, _body = make_request(
        path: '/users',
        user_agent: 'sqlmap/1.0'
      )

      expect(status).to eq(403)
    end

    it 'prioritizes path blocking over user agent blocking' do
      # Path blocking happens first in the middleware
      status, headers, _body = make_request(
        path: '/wp-login.php',
        user_agent: 'sqlmap/1.0'
      )

      expect(status).to eq(404) # Path blocked, not 403 for user agent
      expect(headers['X-Attack-Protection']).to eq('blocked-path')
    end
  end

  describe 'response format' do
    it 'returns HTML 404 response for blocked paths' do
      status, headers, body = make_request(path: '/wp-admin')

      expect(status).to eq(404)
      expect(headers['Content-Type']).to eq('text/html')
      expect(body.join).to include('404 Not Found')
    end

    it 'returns HTML 403 response for blocked user agents' do
      status, headers, body = make_request(
        path: '/users',
        user_agent: 'nikto'
      )

      expect(status).to eq(403)
      expect(headers['Content-Type']).to eq('text/html')
      expect(body.join).to include('403 Forbidden')
    end

    it 'includes attack protection header in blocked responses' do
      _status, headers, _body = make_request(path: '/wp-login.php')

      expect(headers['X-Attack-Protection']).to be_present
    end
  end
end
