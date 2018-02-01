#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module WorkPackages
      module CustomActions
        class CustomActionsAPI < ::API::OpenProjectAPI
          resources :custom_actions do
            params do
              requires :action_id, desc: 'Custom action id', type: Integer
            end
            route_param :action_id do
              post do
                # TODO: check how this can be merged with work_packages_shared_helpers
                @work_package.lock_version = nil
                payload = ::API::V3::WorkPackages::WorkPackageLockVersionPayloadRepresenter.new(@work_package,
                                                                                                current_user: current_user)
                @work_package = payload.from_hash(Hash(request_body))

                custom_action = CustomAction.find(params[:action_id])

                # TODO move into each action
                # TODO handle having multiple values
                attributes = custom_action.actions.map { |a| [a.key.to_s.gsub(/(_id)?$/, '_id'), a.values.first] }.to_h

                call = ::WorkPackages::UpdateService
                       .new(
                         user: current_user,
                         work_package: @work_package
                       )
                       .call(attributes: attributes,
                             send_notifications: notify_according_to_params)

                if call.success?
                  @work_package.reload

                  status 200
                  work_package_representer
                else
                  fail ::API::Errors::ErrorBase.create_and_merge_errors(call.errors)
                end
              end
            end
          end
        end
      end
    end
  end
end
