root = exports ? this
t3d = root.turtle3d

window.onload = ->
  codeMirror = CodeMirror.fromTextArea $('#codeMirrorArea').get 0
  t3d.init document.body
  $('#runButton').click ->
    scene = t3d.run codeMirror.getValue()
    $('#numObjects').html "#{scene.children.length} objects in the scene"
