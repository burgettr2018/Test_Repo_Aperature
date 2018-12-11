$(function() {
	function getValues$() {
		return $('input[id^="internal_user_value_"]')
	}
	function getValue$(id) {
		return $('#internal_user_value_'+ id)
	}
	function getIdFromValue$(value$) {
		return ((value$.get(0)||{}).id||'').replace('internal_user_value_', '')
	}
	function enable$($thing) {
		$thing.closest('.form-group').removeClass('disabled');
		return $thing.prop('disabled', false).removeClass('disabled').each(function(i, e) {
			if (e.selectize) {
				e.selectize.enable();
			}
		});
	}
	function disable$($thing) {
		$thing.closest('.form-group').addClass('disabled');
		return $thing.prop('disabled', true).addClass('disabled').each(function(i, e) {
			if (e.selectize) {
				e.selectize.disable();
			}
		});
	}

	function setVal$($thing, val) {
		return $thing.each(function(i, e) {
			if (e.type === 'checkbox') {
				$(e).prop('checked', new Boolean(val))
			} else if (e.selectize) {
				if (val && val.length) {
					var values = (val || '').split(',');
					for (var i = 0; i < values.length; i++) {
						e.selectize.addOption({
							value: values[i],
							text: values[i]
						});
					}
					e.selectize.setValue(values);
				} else {
					e.selectize.clear();
				}
			} else {
				$(e).val(val);
			}
		})
	}

	function getPts$() {
		return $('input[id^="internal_user_pt_"]')
	}
	function getPt$(id) {
		return $('#internal_user_pt_' + id)
	}
	function getPt$ByCode(app, code) {
		return $('input[type=checkbox][data-application="' + app + '"][data-code="' + code + '"]')
	}
	function getIdFromPt$(pt$) {
		return ((pt$.get(0)||{}).id||'').replace('internal_user_pt_', '');
	}

	function clearResponse() {
		$('#result_div').addClass('hidden');
	}
	function setResponse(type, msg) {
		$('#result_message').text(msg);
		$('#result_div').removeClass('hidden alert-danger alert-success').addClass('alert-'+type);
	}

	getValues$().each(function(i, e) {
		var $e = $(e);
		$e.selectize({
			valueField: 'value',
			labelField: 'value',
			searchField: 'value',
			delimiter: ',',
			persist: false,
			create: function(input) {
				return {
					value: input,
					text: input
				}
			},
			load: function(query, callback) {
				if (!query.length) return callback();
				$.ajax({
					url: '/users/internal/'+ getIdFromValue$($e) + '/values',
					type: 'GET',
					dataType: 'json',
					data: {
						q: query
					},
					xhrFields: {
						withCredentials: true
					},
					error: function() {
						callback();
					},
					success: function(res) {
						var items = res.results.map(function(v) { return {value: v} });
						console.log(items);
						callback(items);
					}
				});
			}
		});
	});
	getPts$().on('change', function(e) {
		var $this = $(this);
		var $val = getValue$(getIdFromPt$($this));
		if ($this.is(':checked')) {
			enable$($val);
		} else {
			setVal$(disable$($val), '');
		}
	});
	$('#internal_user_employee_id').selectize({
		valueField: 'employee_id',
		// labelField: 'employee_id',
		searchField: ['employee_id', 'first_name', 'last_name', 'email'],
		options: [],
		create: false,
		render: {
			option: function(item, escape) {
				return '<div>' +
						escape(item.employee_id) + '<br/>' +
						escape(item.last_name) + ', ' + escape(item.first_name) + ', ' + escape(item.email_address) + ', ' + escape(item.location_name) +
						'</div>'
			},
			item: function (item, escape) {
				return '<div>' +
						escape(item.last_name) + ', ' + escape(item.first_name) + ', ' + escape(item.email_address) +
						'</div>'
			}
		},
		load: function(query, callback) {
			if (!query.length) return callback();
			$.ajax({
				url: '/users/internal/employees',
				type: 'GET',
				dataType: 'json',
				data: {
					q: query
				},
				xhrFields: {
					withCredentials: true
				},
				error: function() {
					callback();
				},
				success: function(res) {
					callback(res.results);
				}
			});
		}
	});

	$('#internal_user_employee_id').on('change', function() {
		disable$($('button[type="submit"]'));
		clearResponse();

		var employee_id = $(this).val();
		$.ajax({
			type: "GET",
			url: "/users/internal/employees/"+employee_id,
			success: function (response_data) {
				$('#internal_user_first_name').val(response_data.data.first_name);
				$('#internal_user_last_name').val(response_data.data.last_name);
				$('#internal_user_email_address').val(response_data.data.email);
				$('#internal_user_hidden_id').val(response_data.data.user_id);
				enable$(getPts$()).prop('checked', false);
				setVal$(getValues$(),'');
				var permissions = (response_data.data.permissions||[]);
				for (var i = 0; i < permissions.length; i++) {
					var $pt = getPt$ByCode(permissions[i].application, permissions[i].code);
					$pt.prop('checked', true);
					var $val = getValue$(getIdFromPt$($pt));
					setVal$(enable$($val), permissions[i].value);
				}
				enable$($('button[type="submit"]'));
			}
		});
	});

	$('button.js-create-update').click(function(e) {
		var $button = $(this);
		if ($button.hasClass('disabled') ) {
			e.preventDefault();
			e.stopPropagation();
		} else {
			var form_contents = $('form').serialize();

			disable$($button).addClass('spinner');
			disable$(getPts$());
			disable$(getValues$());

			$.ajax({
				type: "POST",
				url: "/users/internal",
				data: form_contents,
				success: function (response_data) {
					setResponse('success', 'Success!');
				},
				error: function (jqXHR, textStatus, errorThrown) {
					setResponse('danger', 'Error saving changes!');
				},
				complete: function() {
					enable$(getPts$()).each(function(i, e) {
						var $pt = $(e);
						if ($pt.is(':checked')) {
							enable$(getValue$(getIdFromPt$($pt)));
						}
					});
					enable$($button).removeClass('spinner');
				}
			});
		}
	});

	$(document.body).on("click", "button.disabled", function(e) {
		e.preventDefault();
	});
});

