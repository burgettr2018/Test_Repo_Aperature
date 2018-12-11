//= require lib/selectize.min.js

$(function() {
	if ($.fn.selectize) {
		$('#impersonation_member_id').selectize({
			valueField: 'membershipNumber',
			labelField: 'membershipNumber',
			searchField: 'membershipNumber',
			options: [],
			create: false,
			render: {
				option: function (item, escape) {
					return '<div>' +
							escape(item.membershipNumber) + '<br/>' +
							escape(item.companyName) + ', ' + escape(item.companyStreet1) + ', ' + escape(item.companyCity) + ', ' + escape(item.companyState) + ', ' + escape(item.companyZip) + ', ' + escape(item.companyCountryCodeAlpha3) +
							'</div>'
				}
			},
			load: function (query, callback) {
				if (!query.length) return callback();
				$.ajax({
					url: '/contractor-portal/locations',
					type: 'GET',
					dataType: 'json',
					data: {
						q: query
					},
					xhrFields: {
						withCredentials: true
					},
					error: function () {
						callback();
					},
					success: function (res) {
						callback(res);
					}
				});
			}
		});
		$('#impersonation_member_id').on('change', debounce(function () {
			$('button[type="submit"]').addClass('disabled');

			var memberId = $(this).val();
			$.ajax({
				type: "GET",
				url: "/contractor-portal/location-users",
				data: {member_id: memberId},
				success: function (response_data) {
					var userSelect = $('select#impersonation_user');
					userSelect.empty();
					var userEmails = response_data['user_emails'];
					$.each(userEmails, function (idx, value) {
						userSelect.append('<option value="' + value + '">' + value + ' - ' + response_data['company_name'] + '</option>');
					});

					if (userEmails && userEmails.length) {
						$('button[type="submit"]').removeClass('disabled');
					}
				}
			});
		}, 250));

		$('button.impersonate').click(function (e) {
			if ($(this).hasClass('disabled')) {
				e.preventDefault();
				e.stopPropagation();
			}
		});

		$(document.body).on("click", "button.disabled", function () {
			e.preventDefault();
			alert("click");
		});

		function debounce(fn, delay) {
			var timer = null;
			return function () {
				var context = this, args = arguments;
				clearTimeout(timer);
				timer = setTimeout(function () {
					fn.apply(context, args);
				}, delay);
			};
		}
	}
});
