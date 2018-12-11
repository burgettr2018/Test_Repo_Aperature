(function() {
	var ready = function() {
		var $nameInput = $('input[name="saml_identity_provider[name]"]');
		var $tokenInput = $('input[name="saml_identity_provider[token]"]');
		var $tokenText = $('input[name="saml_identity_provider[tokenText]"]');
		var $issuer = $('input[name="saml_identity_provider[issuer]"]');
		var format = $tokenText.data('format');
		$nameInput.on('keydown keyup change', function(e) {
			var name = $nameInput.val();
			var token = name.replace(/^\s+|\s+$/g,'').toLowerCase().replace(/[^a-z0-9]+/g,'_').replace(/(^_|_$)/g,'');
			$tokenInput.val(token);
			var newAcs = format.replace('$$', token);
			if ($issuer.val() === $tokenText.val()) {
				$issuer.val(newAcs);
			}
			$tokenText.val(newAcs);
		})
	};
	$(document).on('ready pjax:success', ready);
})();
