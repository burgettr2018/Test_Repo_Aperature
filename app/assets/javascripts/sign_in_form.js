// Requires jQuery
'use strict';

var SignInForm = (function() {
  var mailBoxUsersVar = typeof rubyMailBoxUsers === 'undefined' ? '[]' : rubyMailBoxUsers;
  var mailBoxUsers = JSON.parse(mailBoxUsersVar.replace(/&quot;/g, '"'));
  
  function respondToUserEnteringEmail(formSelector, inputSelector, oktaShowSelector, oktaNoShowSelector) {
    $(formSelector + " button[type=submit]").on('click', disableSubmitButton)
    $(inputSelector).on("keyup keypress blur change", function(event) {
      updateForm(formSelector, inputSelector, oktaShowSelector, oktaNoShowSelector)
    });
  }

  function updateForm(formSelector, inputSelector, oktaShowSelector, oktaNoShowSelector) {
    var userLogin = $(inputSelector).val();

    if (isOwensCorningEmail(userLogin) && !isMailBoxEmail(userLogin)) {
      disableForm(formSelector)
      configureFormForOktaSignIn(formSelector)
      hideOktaStuff(formSelector, inputSelector, oktaNoShowSelector)
    } else {
      if (formConfiguredForOktaSignIn(formSelector)) {
        disableForm(formSelector)
        configureFormForDatabaseSignIn(formSelector)
        showOktaStuff(formSelector, inputSelector, oktaNoShowSelector)
      }
    }
  }

  function isOwensCorningEmail(email) {
    return email.match(/@owenscorning.com/i)
  }

  function isMailBoxEmail(email){
    return mailBoxUsers.some(function(emailToTest){ return email.toLowerCase() === emailToTest.toLowerCase() });
  }

  function hideOktaStuff(formSelector, inputSelector, oktaNoShowSelector) {
    $(oktaNoShowSelector).slideUp({
      duration: 400,
      complete: function() {
        enableForm(formSelector)
        setFocus(inputSelector)
        $(oktaNoShowSelector + " input").val('')
      }
    })
  }

  function showOktaStuff(formSelector, inputSelector, oktaNoShowSelector) {
    $(oktaNoShowSelector).slideDown({
      duration: 400,
      complete: function () {
        enableForm(formSelector)
        setFocus(inputSelector)
      }
    })
  }

  function disableForm(formSelector) {
    $(formSelector).on("submit", function(event) { event.preventDefault() })
    $(formSelector + " input").prop("disabled", true)
  }

  function enableForm(formSelector) {
    $(formSelector).off("submit")
    $(formSelector + " input").prop("disabled", false)
  }

  function configureFormForOktaSignIn(formSelector) {
    $(formSelector).attr("method", "get")
    $(formSelector).attr("action", "/users/auth/okta")
    $(formSelector + " button[type=submit]").text("Sign in with Okta")
  }

  function configureFormForDatabaseSignIn(formSelector) {
    $(formSelector).attr("method", "post")
    $(formSelector).attr("action", "/users/sign_in")
    $(formSelector + " button[type=submit]").text("login")
  }

  function formConfiguredForOktaSignIn(formSelector) {
    return $(formSelector + " button[type=submit]").text() === "Sign in with Okta"
  }

  function disableSubmitButton(e) {
    setTimeout(function () {
      $(e.target).prop("disabled", true).addClass('spinner')
    }, 1);
  }

  function setFocus(inputSelector) {
    $(inputSelector).focus()
  }

  return {
    init: function(params) {
      respondToUserEnteringEmail(params.formSelector, params.inputSelector, params.oktaShowSelector, params.oktaNoShowSelector);
    }
  }
})()
