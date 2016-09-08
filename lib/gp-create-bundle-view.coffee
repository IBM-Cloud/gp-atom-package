
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

{MessagePanelView, PlainMessageView} = require 'atom-message-panel'
InputDialog = require '@aki77/atom-input-dialog'

module.exports =
class GpCreateBundleView
  constructor: (credentials) ->
    @credentials = credentials
    @g11n = (require 'g11n-pipeline').getClient(@credentials)

  createBundle: ->
    # Check and see if the bundle was successfully created
    createBundleCallback = (err, results) ->
      messages = new MessagePanelView
        title: 'Globalization Pipeline'
      messages.attach()
      if err
        messages.add new PlainMessageView
           message: 'Bundle already exists'
      else if results.status == 'SUCCESS'
        messages.add new PlainMessageView
          message: 'Bundle created'

    # Try to create the bundle with the input name
    getBundleNameCallback = (bundleName) =>
      @g11n.bundle(bundleName).create({
          sourceLanguage: @credentials.credentials.sourceLanguage
          targetLanguages: @credentials.credentials.targetLanguages
        },createBundleCallback)


    # Make sure the bundle name is valid
    validateBundleName = (bundleName) ->
      message = true
      hasSpaces = /\s/g.test(bundleName)
      hasValidChars = /^[a-z0-9_.\\-]+$/i.test(bundleName)
      if hasSpaces || ! hasValidChars
        return('Bundle name can only contain: numbers, letters, -, ., and _')

    # Display the pop-up asking for the bundle name
    dialog = new InputDialog({
        callback: getBundleNameCallback
        prompt: 'Enter the name of the bundle'
        validate: validateBundleName

    })
    dialog.attach()
