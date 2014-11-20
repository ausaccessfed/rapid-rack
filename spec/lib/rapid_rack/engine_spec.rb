module RapidRack
  RSpec.describe Engine, type: :feature do
    let(:opts) { YAML.load_file('spec/dummy/config/rapidconnect.yml') }
    let(:issuer) { opts['issuer'] }
    let(:audience) { opts['audience'] }
    let(:url) { opts['url'] }
    let(:secret) { opts['secret'] }
    let(:app) { Rails.application }

    subject { last_response }

    context 'get /nonexistent' do
      before { get '/auth/nonexistent' }
      it { is_expected.to be_not_found }
    end

    context 'get /login' do
      before { get '/auth/login' }

      it 'redirects to the url' do
        expect(last_response).to be_redirect
        expect(last_response['Location']).to eq(url)
      end
    end

    context 'post /login' do
      before { post '/auth/login' }
      it { is_expected.to be_method_not_allowed }
    end

    context 'get /logout' do
      before { get '/auth/logout' }

      it 'responds using the receiver' do
        expect(last_response).to be_successful
        expect(last_response.body).to have_content('Logged Out!')
      end
    end

    context 'post /logout' do
      before { post '/auth/logout' }
      it { is_expected.to be_method_not_allowed }
    end

    context 'get /jwt' do
      before { get '/auth/jwt' }
      it { is_expected.to be_method_not_allowed }
    end

    context 'post /jwt' do
      before { post '/auth/jwt', assertion: assertion }

      let(:attrs) do
        {
          cn: 'Test User', displayname: 'Test User X', surname: 'User',
          givenname: 'Test', mail: 'testuser@example.com', o: 'Test Org',
          auedupersonsharedtoken: 'SharedTokenForTestUser_____',
          edupersonscopedaffiliation: 'member@example.com',
          edupersonprincipalname: 'testuser@example.com',
          edupersontargetedid: "#{issuer}!#{audience}!abcd"
        }
      end

      let(:valid_claims) do
        {
          aud: audience, iss: issuer, iat: Time.now, typ: 'authnresponse',
          nbf: 1.minute.ago, exp: 2.minutes.from_now,
          jti: SecureRandom.urlsafe_base64(24),
          :'https://aaf.edu.au/attributes' => attrs
        }
      end

      let(:assertion) { JSON::JWT.new(claims).sign(secret).to_s }

      context 'with an invalid assertion' do
        let(:assertion) { 'x.y.z' }
        it { is_expected.to be_bad_request }

        it 'responds with the error handler' do
          expect(last_response.body).to have_content('Error!')
        end
      end

      context 'with a valid assertion' do
        let(:claims) { valid_claims }
      end

      shared_examples 'an invalid claims set' do
        it { is_expected.to be_bad_request }
      end

      context 'with a nil audience' do
        let(:claims) { valid_claims.merge(aud: nil) }
        it_behaves_like 'an invalid claims set'
      end

      context 'with an invalid audience' do
        let(:claims) { valid_claims.merge(aud: 'invalid') }
        it_behaves_like 'an invalid claims set'
      end

      context 'with a nil issuer' do
        let(:claims) { valid_claims.merge(iss: nil) }
        it_behaves_like 'an invalid claims set'
      end

      context 'with an invalid issuer' do
        let(:claims) { valid_claims.merge(iss: 'invalid') }
        it_behaves_like 'an invalid claims set'
      end

      context 'with a nil type' do
        let(:claims) { valid_claims.merge(typ: nil) }
        it_behaves_like 'an invalid claims set'
      end

      context 'with an invalid type' do
        let(:claims) { valid_claims.merge(typ: 'blarghn') }
        it_behaves_like 'an invalid claims set'
      end

      context 'with a nil jti' do
        let(:claims) { valid_claims.merge(jti: nil) }
        it_behaves_like 'an invalid claims set'
      end

      context 'with a replayed jti' do
        let(:claims) { valid_claims.merge(jti: 'blarghn') }
        it_behaves_like 'an invalid claims set'
      end

      context 'with a nil nbf' do
        let(:claims) { valid_claims.merge(nbf: nil) }
        it_behaves_like 'an invalid claims set'
      end

      context 'with an invalid nbf' do
        let(:claims) { valid_claims.merge(nbf: 2.minutes.from_now) }
        it_behaves_like 'an invalid claims set'
      end

      context 'with a non-numeric nbf' do
        let(:claims) { valid_claims.merge(nbf: 'a') }
        it_behaves_like 'an invalid claims set'
      end

      context 'with a nil exp' do
        let(:claims) { valid_claims.merge(exp: nil) }
        it_behaves_like 'an invalid claims set'
      end

      context 'with an invalid exp' do
        let(:claims) { valid_claims.merge(exp: 1.minute.ago) }
        it_behaves_like 'an invalid claims set'
      end

      context 'with a non-numeric exp' do
        let(:claims) { valid_claims.merge(exp: 'a') }
        it_behaves_like 'an invalid claims set'
      end

      context 'with a nil iat' do
        let(:claims) { valid_claims.merge(iat: nil) }
        it_behaves_like 'an invalid claims set'
      end

      context 'with an invalid iat' do
        let(:claims) { valid_claims.merge(iat: 10.minutes.ago) }
        it_behaves_like 'an invalid claims set'
      end

      context 'with a non-numeric iat' do
        let(:claims) { valid_claims.merge(iat: 'a') }
        it_behaves_like 'an invalid claims set'
      end
    end
  end
end
