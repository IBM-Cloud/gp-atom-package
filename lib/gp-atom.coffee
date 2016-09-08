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

GpUploadBundleView = require './gp-upload-bundle-view'
GpCreateBundleView = require './gp-create-bundle-view'
GpDeleteBundleView = require './gp-delete-bundle-view'
GpDownloadBundleView = require './gp-download-bundle-view'
packageConfig = require './config-schema.json'

{CompositeDisposable} = require 'atom'

module.exports = GpAtom =
  config: packageConfig
  gpUpload: null
  gpCreate: null
  gpDelete: null
  gpDownload: null
  subscriptions: null
  credentials: {credentials: {}}

  activate: (state) ->

    @credentials.credentials.url = atom.config.get('gp-atom.url')
    @credentials.credentials.userId = atom.config.get('gp-atom.userId')
    @credentials.credentials.password = atom.config.get('gp-atom.password')
    @credentials.credentials.instanceId = atom.config.get('gp-atom.instanceId')
    @credentials.credentials.sourceLanguage = atom.config.get('gp-atom.sourceLanguage')
    @credentials.credentials.targetLanguages = atom.config.get('gp-atom.targetLanguages')

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands for accessing the Globalization Pipeline service
    @subscriptions.add atom.commands.add 'atom-workspace', 'gp-atom:uploadBundle': => @uploadBundle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'gp-atom:createBundle': => @createBundle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'gp-atom:deleteBundle': => @deleteBundle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'gp-atom:downloadBundle': => @downloadBundle()

  deactivate: ->
    @subscriptions.dispose()

  uploadBundle: ->
    @gpUpload = new GpUploadBundleView(@credentials)

  createBundle: ->
    @gpCreate = new GpCreateBundleView(@credentials)
    @gpCreate.createBundle()

  deleteBundle: ->
    @gpDelete = new GpDeleteBundleView(@credentials)

  downloadBundle: ->
    @gpDownload = new GpDownloadBundleView(@credentials)
