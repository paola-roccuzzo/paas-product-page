require './models/model'

module Forms

	class Invite < Model
		field :person_name,                  String, :label => 'Name'
		field :person_email,                 String, :match => /.+@.+\..+/, :label => 'Email address'
		field :person_is_manager,            Boolean
	end

	class Signup < Model
		field :person_email,                 String, :required => true, :match => /.+@.+\.gov\.uk$/, :min => 5, :label => 'Email address'
		field :person_name,                  String, :required => true, :min => 2, :label => 'Name'
		field :person_is_manager,            Boolean
		field :department_name,              String, :required => true
		field :service_name,                 String, :required => true
		field :invite_users,                 Boolean
		field :invites,                      Array, :of => Invite

		def subject
			"#{Date.today.to_s} Registration Request"
		end

		def message
			msg = [
				"New organisation/account signup request from website",
				"",
				"From: #{person_name}",
				"Email: #{person_email} #{"(org manager)" if person_is_manager}",
				"Department: #{department_name}",
				"Team: #{service_name}",
			].join("\n")
			if invite_users
				msg << ([
					"",
					"They would also like to invite:",
				] + invites.map{ |invite| "#{invite.person_email} #{"(org manager)" if invite.person_is_manager}" }).join("\n")
			end
			msg
		end

		def to_ticket
			ticket = Deskpro::Ticket.new({
				subject: subject,
				message: message,
				person_email: person_email,
				person_name: person_name,
				label: ['paas'],
			})
			ticket.agent_team_id = ENV['DESKPRO_TEAM_ID'].to_i if ENV['DESKPRO_TEAM_ID']
			ticket
		end
	end

	module Helpers

		# return comma seperated list of errors from validation if resourse has been validated
		def errors_for(record, field)
			return nil if !record.validated?
			errs = record.errors[field]
			return nil if !errs or errs.size == 0
			return errs.join(", ")
		end

		def input_for(record, name, **kwargs)
			field = record.class.fields[name]
			raise "#{record} has no field #{name}" if not field
			erb :"partials/_input", :locals => {
				name: name,
				label: kwargs[:label] || name.to_s.gsub(/_/,' '),
				hint: kwargs[:hint] || '',
				value: record.send(name),
				error: errors_for(record, name)
			}
		end

		def radio_for(record, name, **kwargs)
			field = record.class.fields[name]
			raise "#{record} has no field #{name}" if not field
			erb :"partials/_radio", :locals => {
				name: name,
				label: kwargs[:label] || name.to_s.gsub(/_/,' '),
				hint: kwargs[:hint] || '',
				value: record.send(name),
				error: errors_for(record, name),
				options: kwargs[:options] || [],
			}
		end

	end

end
