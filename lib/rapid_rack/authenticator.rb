require 'json/jwt'
require 'rack/utils'

module RapidRack
  class Authenticator
    def initialize(app, opts)
      @app = app
      @url = opts[:url]
      @receiver = opts[:receiver]
      @secret = opts[:secret]
      @issuer = opts[:issuer]
      @audience = opts[:audience]
    end

    def call(env)
      sym = DISPATCH[env['PATH_INFO']]
      return send(sym, env) if sym

      [404, {}, "Not found: #{env['PATH_INFO']}"]
    end

    private

    InvalidClaim = Class.new(StandardError)
    private_constant :InvalidClaim

    DISPATCH = {
      '/login' => :initiate,
      '/jwt' => :callback
    }
    private_constant :DISPATCH

    def initiate(env)
      return method_not_allowed unless method?(env, 'GET')

      [302, { 'Location' => @url }, '']
    end

    def callback(env)
      return method_not_allowed unless method?(env, 'POST')
      params = Rack::Utils.parse_query(env['rack.input'].read)

      with_claims(params['assertion']) do |claims|
        @receiver.new.receive(claims)
      end
    end

    def with_claims(assertion)
      claims = JSON::JWT.decode(assertion, @secret)
      validate_claims(claims)
      yield claims
    rescue JSON::JWT::Exception
      bad_request
    rescue InvalidClaim
      bad_request
    end

    def validate_claims(claims)
      reject_claim_if(claims, 'aud') { |v| v != @audience }
      reject_claim_if(claims, 'iss') { |v| v != @issuer }
      reject_claim_if(claims, 'typ') { |v| v != 'authnresponse' }
      reject_claim_if(claims, 'jti', &method(:replayed?))
      reject_claim_if(claims, 'nbf', &:zero?)
      reject_claim_if(claims, 'nbf', &method(:future?))
      reject_claim_if(claims, 'exp', &method(:expired?))
      reject_claim_if(claims, 'iat', &method(:skewed?))
    end

    def replayed?(jti)
      !@receiver.new.register_jti(jti)
    end

    def skewed?(iat)
      (iat - Time.now.to_i).abs > 60
    end

    def expired?(exp)
      Time.at(exp) < Time.now
    end

    def future?(nbf)
      Time.at(nbf) > Time.now
    end

    def reject_claim_if(claims, key)
      val = claims[key]
      fail(InvalidClaim, "nil #{key}") unless val
      fail(InvalidClaim, "bad #{key}: #{val}") if yield(val)
    end

    def method?(env, method)
      env['REQUEST_METHOD'] == method
    end

    def method_not_allowed
      [405, {}, 'Method not allowed']
    end

    def bad_request
      [400, {}, '']
    end
  end
end
