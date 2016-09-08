# Copyright IBM Corp. 2016
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# @author Steven Atkin
#

GpLanguageListView = require './gp-language-list-view'
{SelectListView} = require 'atom-space-pen-views'
{MessagePanelView, PlainMessageView} = require 'atom-message-panel'

module.exports =
class GpDownloadBundleView extends SelectListView
  gpLanguage: null

  initialize: (credentials)->
    super
    # Credentials for accessing globalization pipeline service
    @credentials = credentials
    @addClass('overlay from-top')

    @g11n = (require 'g11n-pipeline').getClient(@credentials)

    # Need fat arrow to access the enclosing scope
    # Callback for showing the bundle list
    displayBundlesCallback = (err, bundles) =>
      if err
        messages = new MessagePanelView
          title: 'Globalization Pipeline'
        messages.attach()
        messages.add new PlainMessageView
           message: 'Could not get bundle list'
      else
        bundleList = Object.keys(bundles)
        @setItems(bundleList)
        @panel ?= atom.workspace.addModalPanel(item: this)
        @panel.show()
        @focusFilterEditor()

    # Get the available list of bundles
    @g11n.bundles({}, displayBundlesCallback)

  viewForItem: (item) ->
    "<li>#{item}</li>"

  confirmed: (bundleName) ->
    @panel.destroy();

    # Need fat arrow to access the enclosing scope
    languageListCallback = (err, langs) =>
      if err || langs.targetLanguages.length == 0
        messages = new MessagePanelView
          title: 'Globalization Pipeline'
        messages.attach()
        messages.add new PlainMessageView
           message: 'Could not get list of languages'
      else
        # Call the view for displaying the languages
        @gpLanguage = new GpLanguageListView(@credentials,
                          bundleName,
                          langs.targetLanguages)


    # Get the list of available languages for the bundle
    @g11n.bundle(bundleName).getInfo({
      fields: 'targetLanguages'
      }, languageListCallback)

  cancelled: ->
    @panel.destroy()
