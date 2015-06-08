module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    # https://github.com/gruntjs/grunt-contrib-coffee
    coffee:
      dev:
        expand: true
        cwd: ''
        src: [
          '*.coffee'
          '!Gruntfile.coffee'
          'routes/*.coffee'
          'public/**/*.coffee'
          'models/*.coffee'
        ]
        dest: '.'
        ext: '.js'
        options:
          bare: true
    nodemon:
      dev:
        script: 'bin/www'
        options:
          env:
            DEBUG: 'youtube:*'
          ext: 'js'
          # livereload: true
    watch:
      coffee:
        files: [
          '*.coffee'
          # 'models/*.coffee'
          'routes/*.coffee'
          'public/**/*.coffee' 
        ]
        tasks: [
          'coffee:dev'
        ]
        options:
          livereload: true
      jade:
        files: [
          'views/**/*.jade'
        ]
        options:
          livereload: true
      css:
        files: [
          'public/**/*.css'
        ]
        options:
          livereload: true
    concurrent:
      dev:
        tasks: [
          'nodemon:dev'
          'watch'
        ]
        options:
          logConcurrentOutput: true

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-nodemon'
  grunt.loadNpmTasks 'grunt-concurrent'

  grunt.registerTask 'serve', ['coffee:dev', 'concurrent:dev']

  grunt.registerTask 'default', ->
    grunt.log.writeln """
    Usage:
      - grunt serve
    """.yellow