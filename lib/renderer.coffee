os = require 'os'
path = require 'path'
_ = require 'underscore-plus'
fs = require 'fs-plus'
cheerio = require 'cheerio'
aglio = require 'aglio'
{$} = require 'atom-space-pen-views'

{resourcePath} = atom.getLoadSettings()
packagePath = path.dirname(__dirname)

exports.toDOMFragment = (text='', filePath, grammar, callback) ->
  render text, filePath, (error, html) ->
    return callback(error) if error?

    template = document.createElement('template')
    template.innerHTML = html
    domFragment = template.content.cloneNode(true)

    callback(null, domFragment)

exports.toHTML = (text='', filePath, grammar, callback) ->
  render text, filePath, callback

render = (text, filePath, callback) ->
  template = "#{path.dirname __dirname}/templates/api-blueprint-preview.jade"

  includePath = path.dirname filePath # for Aglio include directives

  opt = {
    themeTemplate: template
    includePath: includePath
  }

  aglio.render text, opt, (err, html, warns)->
    if err then return callback(err)
    console.log err
    callback null, resolveImagePaths(html, filePath)

resolveImagePaths = (html, filePath) ->
  [rootDirectory] = atom.project.relativizePath(filePath)
  o = cheerio.load(html)
  for imgElement in o('img')
    img = o(imgElement)
    if src = img.attr('src')
      continue if src.match(/^(https?|atom):\/\//)
      continue if src.startsWith('data:image/')
      continue if src.startsWith(process.resourcesPath)
      continue if src.startsWith(resourcePath)
      continue if src.startsWith(packagePath)

      if src[0] is '/'
        unless fs.isFileSync(src)
          img.attr('src', path.join(rootDirectory, src.substring(1)))
      else
        img.attr('src', path.resolve(path.dirname(filePath), src))

  o.html()
