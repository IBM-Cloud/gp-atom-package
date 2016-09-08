#
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

module.exports =
class GpUploadBundleView extends SelectListView
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
    editor = atom.workspace.getActiveTextEditor()
    fileName = editor.getBuffer().file.path
    fileExt = path.extname(fileName).toLowerCase()
    parsed = {}
    docContent = editor.getBuffer().getText()

    # bundle was selected to upload content to

    # JSON file type
    if fileExt == '.json'
      try
        parsed = JSON.parse(docContent)
      catch error
        parsed = {}
    # Java properties file
    else if fileExt == '.properties'
      props = require 'properties-parser'
      try
        parsed = props.parse(docContent)
      catch error
        parsed = {}
    # AMD JavaScript file
    else if fileExt == '.js'
      esprima = require 'esprima'
      try
        # get the abstract syntax tree for the AMD resource
        ast = esprima.parse(docContent, {
                        range: true
                        raw: true
        })
        # grab the define function out of the ast
        defines = ast.body.filter((node) ->
          return node.expression.callee.name == 'define')[0]

        # grab the resource bundle argument to the define
        args = defines.expression['arguments']

        # Grab the root object of the bundle
        bundle = args.filter((arg) ->
                        return arg.type == 'ObjectExpression')[0]

        # Grab the array of key value pairs
        pairs = bundle.properties[0].value.properties

        for pair in pairs
          # add the key value pair to the json object
          parsed[pair.key.name] = pair.value.value

      catch error
        parsed = {}
    # Gettext file
    else if fileExt == '.pot'
      po2json = require 'po2json'
      try
        # parse the content and return as key value pairs
        potData = po2json.parse(docContent, {format: 'mf'})
        #
        # For .pot files we need to copy the keys over to the values
        # for each string in the file
        #
        for k,v of potData
          parsed[k] = k
      catch error
        parsed = {}
    # no valid file type found
    else
      messages = new MessagePanelView
        title: 'Globalization Pipeline'
      messages.attach()
      messages.add new PlainMessageView
        message: 'This file type is not supported'
      return

    # Callback for displaying status message
    uploadBundlesCallback = (err, results) ->
      messages = new MessagePanelView
        title: 'Globalization Pipeline'
      messages.attach()
      if err
        messages.add new PlainMessageView
           message: 'Bundle not uploaded'
      else if results.status == 'SUCCESS'
        messages.add new PlainMessageView
          message: 'Bundle uploaded'


    #Call the pipeline service to upload the strings
    length = Object.keys(parsed).length
    if length > 0
      @g11n.bundle(bundleName).uploadStrings({
        languageId: @credentials.credentials.sourceLanguage
        strings: parsed
        }, uploadBundlesCallback)

  cancelled: ->
    @panel.destroy()
