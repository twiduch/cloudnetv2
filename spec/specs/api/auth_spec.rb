require 'spec_helper'

describe API do
  include Rack::Test::Methods

  def app
    API
  end

  describe Routes::Auth do
    describe 'Registration' do
      it 'should register a new user' do
        options = {
          full_name: 'Tester',
          email: 'valid@email.com'
        }
        post '/auth/register', options

        expect(last_response.status).to eq 201
        response = JSON.parse(last_response.body)
        expect(response['message']).to match(/Thank you/)
      end

      it 'should know when the email address is already taken' do
        user = Fabricate :user, email: 'existing@email.com'
        options = {
          full_name: 'Tester',
          email: user.email
        }
        post '/auth/register', options

        expect(last_response.status).to eq 400
        response = JSON.parse(last_response.body)
        expect(response['message']['error']['email'].first).to match(/is already taken/)
      end

      it 'should notice invalid params' do
        options = {
          full_name: 'Tester',
          email: 'invalidemail.com'
        }
        post '/auth/register', options

        expect(last_response.status).to eq 400
        response = JSON.parse(last_response.body)
        expect(response['message']['error'][0]['messages'][0]).to match(/is invalid/)
      end
    end

    describe 'Confirmation' do
      it 'should confirm a registered user' do
        token = SymmetricEncryption.encrypt 'token'
        user = Fabricate :user, encrypted_confirmation_token: token

        options = {
          token: 'token',
          password: 'abcd1234'
        }
        put '/auth/confirm', options
        user.reload

        expect(last_response.status).to eq 200
        response = JSON.parse(last_response.body)
        expect(response['message']).to match(/You are now confirmed/)
        expect(user.status).to eq :active
      end

      it 'should not confirm a registered user with an invalid token' do
        token = SymmetricEncryption.encrypt 'abc123'
        user = Fabricate :user, encrypted_confirmation_token: token

        options = {
          token: 'wrong token',
          password: 'abcd1234'
        }
        put '/auth/confirm', options

        expect(last_response.status).to eq 400
        response = JSON.parse(last_response.body)
        expect(response['error']).to match(/Confirmation failed/)
        expect(user.status).to eq :pending
      end
    end

    describe 'Login' do
      it 'should return a login token' do
        user = Fabricate :user, status: :active
        options = {
          email: user.email,
          password: 'abcd1234'
        }
        get '/auth/token', options
        user.reload

        expect(last_response.status).to eq 200
        response = JSON.parse(last_response.body)
        expect(response['token']).to eq user.login_token
      end

      it 'should return a new login token replacing the an old token' do
        encrypted = SymmetricEncryption.encrypt 'old_token'
        user = Fabricate :user, status: :active, encrypted_login_token: encrypted
        old_token = user.login_token
        options = {
          email: user.email,
          password: 'abcd1234'
        }
        get '/auth/token', options
        user.reload

        expect(last_response.status).to eq 200
        response = JSON.parse(last_response.body)
        expect(response['token']).to eq user.login_token
        expect(user.login_token).not_to eq old_token
      end

      it 'should not return a login token for a wrong password' do
        user = Fabricate :user, status: :active
        options = {
          email: user.email,
          password: 'abcd1234WRONG!'
        }
        get '/auth/token', options
        user.reload

        expect(last_response.status).to eq 403
        response = JSON.parse(last_response.body)
        expect(response['error']).to match(/Invalid password/)
      end
    end
  end
end
