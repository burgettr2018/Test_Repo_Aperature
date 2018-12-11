(function() {
	var ready = function() {
		var $providerInput = $('select[name="user[provider]"]');
		if ($providerInput.length > 0) {
			var $firstnameField = $('div#user_first_name_field');
			var $lastnameField = $('div#user_last_name_field');
			var $passwordRow = $('div#user_password_field');

			function setFieldState(val) {
				if (val === 'database') {
					$firstnameField.show();
					$lastnameField.show();
					$passwordRow.show();
					$passwordRow.find('input').prop('required',true);
				} else {
					$firstnameField.hide();
					$lastnameField.hide();
					$passwordRow.hide();
					$passwordRow.find('input').prop('required',false);
				}
			}

			setFieldState($providerInput.val());

			$providerInput.on('change', function (e) {
				setFieldState($providerInput.val());
			});
		}
		var $usernameInput = $('input[name="user[username]"]');
		var $emailInput = $('input[name="user[email]"]');
		var email = $emailInput.val();
		var initialUsername = $usernameInput.val();
		var initialPotentialUsername = (email||'').split('@')[0];
		var updateUsername = initialUsername === '' || initialUsername === initialPotentialUsername;
		$emailInput.on('keydown keyup change', function(e) {
			if (updateUsername) {
				var email = $emailInput.val();
				var potentialUsername = email.split('@')[0];
				$usernameInput.val(potentialUsername);
			}
		});
		$usernameInput.on('keydown keyup change', function(e) {
			updateUsername = $(this).val() === '';
		});
	};
	$(document).on('ready pjax:success', ready);
})();
