dom = require 'view_helper'
api = require 'lib/api'

describe 'Auth views', ->

  # TODO: test for validation

  beforeEach ->
    sandbox.spy(api, 'request')

  it 'should register a user', ->
    dom.gotoPath '/auth/register'
    dom.setValue('.fullname-input', 'Tester')
    dom.setValue('.email-input', 'test@email.com')
    dom.submit('.login-form')
    dom.ajaxStub({
      message: true
    })
    expect(
      api.request.calledWith(
        'POST',
        '/auth/register',
        { full_name: 'Tester', email: 'test@email.com' }
      )
    ).to.be.ok
    dom.should.contain 'Thanks for registering'

  it 'should confirm a user', ->
    dom.gotoPath '/auth/confirm?token=123'
    dom.setValue('.password-input', 'pass123')
    dom.setValue('.passwordconfirm-input', 'pass123')
    dom.submit('.login-form')
    dom.ajaxStub({
      message: true
    })
    expect(
      api.request.calledWith(
        'PUT',
        '/auth/confirm',
        { token: '123', password: 'pass123' }
      )
    ).to.be.ok
    dom.should.contain 'Your account has been confirmed'

  describe 'Logging in', ->
    it 'should login a user with the correct credentials', ->
      dom.gotoPath '/auth/login'
      dom.setValue('.email-input', 'test@email.com')
      dom.setValue('.password-input', 'pass123')
      dom.submit('.login-form')
      dom.ajaxStub({
        token: 'token123'
      })
      expect(
        api.request.calledWith(
          'GET',
          '/auth/token',
          { email: 'test@email.com', password: 'pass123' }
        )
      ).to.be.ok
      expect(localStorage.token).to.eq 'token123'
      expect(window.location.pathname).to.eq '/dashboard'
      dom.should.contain 'Dashboard'

    it 'should not login a user with incorrect credentials', ->
      dom.gotoPath '/auth/login'
      dom.setValue('.password-input', 'pass123')
      dom.setValue('.email-input', 'test@email.com')
      dom.submit('.login-form')
      dom.ajaxStub({
        message: {
          error: true
        }
      })
      expect(localStorage.token).to.not.eq 'token123'
      expect(window.location.pathname).to.eq '/auth/login'
      dom.should.contain 'problem'
      dom.should.not.contain 'Dashboard'
