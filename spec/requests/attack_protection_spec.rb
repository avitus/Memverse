# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Attack Protection Integration', type: :request do
  describe 'WordPress attack path protection' do
    it 'blocks wp-login.php requests' do
      get '/wp-login.php'

      expect(response).to have_http_status(:not_found)
      expect(response.headers['X-Attack-Protection']).to eq('blocked-path')
    end

    it 'blocks wp-admin requests' do
      get '/wp-admin/index.php'

      expect(response).to have_http_status(:not_found)
    end

    it 'blocks xmlrpc.php requests' do
      post '/xmlrpc.php'

      expect(response).to have_http_status(:not_found)
    end

    it 'blocks phpmyadmin requests' do
      get '/phpmyadmin/index.php'

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'malicious user agent protection' do
    it 'blocks requests with sqlmap user agent' do
      get '/', headers: { 'HTTP_USER_AGENT' => 'sqlmap/1.0' }

      expect(response).to have_http_status(:forbidden)
      expect(response.headers['X-Attack-Protection']).to eq('blocked-request')
    end

    it 'blocks requests with nikto user agent' do
      get '/', headers: { 'HTTP_USER_AGENT' => 'Nikto/2.1.6' }

      expect(response).to have_http_status(:forbidden)
    end

    it 'blocks requests with wpscan user agent' do
      get '/', headers: { 'HTTP_USER_AGENT' => 'WPScan v3.8.0' }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'legitimate request handling' do
    it 'allows normal requests to root path' do
      get '/'

      expect(response).to have_http_status(:ok)
    end

    it 'allows requests with legitimate user agents' do
      get '/users/sign_in', headers: {
        'HTTP_USER_AGENT' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'
      }

      expect(response).to have_http_status(:ok)
    end

    it 'allows requests to Rails admin (not wp-admin)' do
      # This should reach the Rails admin route, not be blocked
      # It will redirect to login, but won't be blocked by middleware
      get '/admin'

      # Should not be blocked (404/403 from middleware)
      expect(response.status).not_to eq(404)
      expect(response.headers['X-Attack-Protection']).to be_nil
    end
  end

  describe 'IP spoofing handling' do
    it 'handles conflicting IP headers gracefully' do
      # Simulate IP spoofing attempt
      get '/', headers: {
        'HTTP_CLIENT_IP' => '192.168.1.100',
        'HTTP_X_FORWARDED_FOR' => '10.0.0.1'
      }

      # Should not raise an error or return 500
      # Middleware should catch and return 403
      expect(response).to have_http_status(:forbidden)
      expect(response.headers['X-Attack-Protection']).to eq('blocked-request')
    end

    it 'allows requests with consistent IP headers' do
      get '/', headers: {
        'HTTP_CLIENT_IP' => '10.0.0.1',
        'HTTP_X_FORWARDED_FOR' => '10.0.0.1'
      }

      # Should not be blocked for IP spoofing
      expect(response.status).not_to eq(403)
      expect(response.headers['X-Attack-Protection']).to be_nil
    end
  end

  describe 'middleware stack integration' do
    it 'blocks attacks before they reach the application' do
      # Verify that blocked requests don't trigger ActionController
      expect_any_instance_of(ApplicationController).not_to receive(:process_action)

      get '/wp-login.php'

      expect(response).to have_http_status(:not_found)
    end

    it 'blocks attacks before they reach RemoteIp middleware' do
      # Create a scenario that would trigger RemoteIp::IpSpoofAttackError
      # but our middleware should catch it first
      # The middleware logs using a block, so we verify the block is called
      expect(Rails.logger).to receive(:warn) do |*args, &block|
        if block
          message = block.call
          expect(message).to include('IP Spoofing attempt detected')
        end
      end

      get '/', headers: {
        'HTTP_CLIENT_IP' => '192.168.1.100',
        'HTTP_X_FORWARDED_FOR' => '10.0.0.1'
      }

      # Should be handled gracefully
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'attack pattern detection' do
    it 'detects WordPress enumeration attempts' do
      paths = [
        '/wp-login.php',
        '/wp-admin/',
        '/wp-content/plugins/example/',
        '/xmlrpc.php',
        '/wp-config.php'
      ]

      paths.each do |path|
        get path
        expect(response).to have_http_status(:not_found),
                            "Expected #{path} to be blocked with 404"
      end
    end

    it 'detects PHP admin panel scanning' do
      paths = [
        '/phpmyadmin',
        '/phpMyAdmin/index.php',
        '/admin.php',
        '/myadmin',
        '/dbadmin'
      ]

      paths.each do |path|
        get path
        expect(response).to have_http_status(:not_found),
                            "Expected #{path} to be blocked with 404"
      end
    end

    it 'detects configuration file access attempts' do
      paths = [
        '/.env',
        '/.git/config',
        '/backup.sql',
        '/config.php',
        '/database.php'
      ]

      paths.each do |path|
        get path
        expect(response).to have_http_status(:not_found),
                            "Expected #{path} to be blocked with 404"
      end
    end
  end
end
