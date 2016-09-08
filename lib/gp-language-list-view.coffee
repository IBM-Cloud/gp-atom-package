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

{SelectListView} = require 'atom-space-pen-views'
{MessagePanelView, PlainMessageView} = require 'atom-message-panel'
path = require 'path'
fs = require 'fs'

module.exports =
class GpLanguageListView extends SelectListView
  initialize: (credentials, bundleName, targetLanguages)->
    super
    # Credentials for accessing globalization pipeline service
    @credentials = credentials
    @bundleName = bundleName
    @addClass('overlay from-top')

    @g11n = (require 'g11n-pipeline').getClient(@credentials)

    # Display the languages for the bundle
    @setItems(targetLanguages)
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  viewForItem: (item) ->
    "<li>#{item}</li>"

  confirmed: (language) ->
    @panel.destroy();

    # Need fat arrow to access the enclosing scope
    stringsCallback = (err, results) =>
      if err
        messages = new MessagePanelView
          title: 'Globalization Pipeline'
        messages.attach()
        messages.add new PlainMessageView
           message: 'Could not get bundle strings'
      else
        formatted = JSON.stringify(results.resourceStrings, null, 2)
        fileName = @bundleName + '_' + language + '.json'
        createFile(fileName, formatted)

    # Get the key value pairs of the bundle for the language
    @g11n.bundle(@bundleName).getStrings({
      languageId: language
      }, stringsCallback)

  cancelled: ->
    @panel.destroy()

  # Write the downloaded bundle file to the disk
  createFile = (fileName, content) ->
    try
      # Try to write to the current folder
      fs.writeFileSync(fileName, content)
      fullPath = fs.realpathSync(fileName, [])
      atom.workspace.open(fullPath)
    catch error
      mktmpdir = require 'mktmpdir'
      # Try to write to the temp folder
      createTempCallback = (err, dir) =>
        try
          fileName = path.join(dir, fileName)
          fs.writeFileSync(fileName, content)
          fullPath = fs.realpathSync(fileName, [])
          atom.workspace.open(fullPath)
        catch error
          # No ability to write to temp so fail
          messages = new MessagePanelView
            title: 'Globalization Pipeline'
          messages.attach()
          messages.add new PlainMessageView
             message: "You don't have permission to save the bundle in this location"

      # Create the temp folder and write using the callback
      mktmpdir(createTempCallback)
