dom = require 'dom_helper'

describe 'Auth views', ->

  # TODO: test for validation

  it 'should register a user', (done) ->
    dom.load '/auth/register', ->
      $('.fullname-input').val 'Tester'
      $('.email-input').val 'test@email.com'
      $('.login-form').submit()
      dom.xhrResponseFor '/auth/register', {
        json: {
          message: 'success'
        }
      }
      expect($('.form-feedback').text()).to.eq 'Thanks for registering. An email will be sent shortly.'
      done()

  it 'should confirm a user', (done) ->
    dom.load '/auth/confirm', ->
      $('.password-input').val 'pass123'
      $('.passwordconfirm-input').val 'pass123'
      $('.login-form').submit()
      dom.xhrResponseFor '/auth/confirm', {
        json: {
          message: 'success'
        }
      }
      expect($('.form-feedback').text()).to.eq 'Your account has been confirmed, please login'
      done()

  describe 'Logging in', ->

    before ->
      @m = require 'mithril'

    it 'should login a user with the correct credentials', (done) ->
      dom.load '/auth/login', =>
        $('.email-input').val 'test@email.com'
        $('.password-input').val 'pass123'
        $('.login-form').submit()
        dom.xhrResponseFor '/auth/token', {
          json: {
            token: 'token123'
          }
        }
        expect(localStorage.token).to.eq 'token123'
        expect(@m.route()).to.eq '/dashboard'
        done()

    it 'should not login a user with incorrect credentials', (done) ->
      dom.load '/auth/login', =>
        $('.email-input').val 'test@email.com'
        $('.password-input').val 'pass123'
        $('.login-form').submit()
        dom.xhrResponseFor '/auth/token', {
          json: {
            error: 'bad'
          }
        }
        expect(localStorage.token).to.not.eq 'token123'
        expect(@m.route()).to.eq '/auth/login'
        done()
