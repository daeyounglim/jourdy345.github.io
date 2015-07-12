module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    less:
      dev:
        files:
          'public/stylesheets/style.min.css': 'public/stylesheets/style.less'
    cssmin:
      target:
        files: [
          expand: true
          cwd: ''
          src: [
            'public/bower_components/typeahead.js-bootstrap3.less/*.css'
            'public/bower_components/offline/themes/offline-language-english.css'
            'public/bower_components/offline/themes/offline-theme-dark.css'
            'public/bower_components/messenger/build/css/messenger-theme-air.css'
            'public/bower_components/messenger/build/css/messenger.css'
            'public/stylesheets/*.css'
            '!*.min.css'
          ]
          dest: '.'
          ext: '.min.css'
        ]
    uglify:
      my_target:
        files:
          # 'public/javascripts/output.min.js': ['src/main.js']
          'public/javascripts/output2.min.js': ['public/bower_components/messenger/build/js/messenger-theme-flat.js']
    shell:
      deploy:
        command: """
        ssh listify "cd ~/jourdy345.github.io/;. deploy.sh"
        """
        # ssh listify "source .bashrc; cd ~/jourdy345.github.io/; git pull; npm install; cd ./public/; bower install; cd ..; grunt coffee:dev; rs;"
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
          'db/*.coffee'
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
          'src/*.coffee'
          'db/*.coffee'
          'models/*.coffee'
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
      less:
        files: [
          'public/stylesheets/*.less'
        ]
        tasks: [
          'less:dev'
        ]
        options:
          livereload: false
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
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-concurrent'


  grunt.registerTask 'serve', ['coffee:dev', 'less:dev', 'concurrent:dev']
  grunt.registerTask 'deploy', ['shell:deploy']
  grunt.registerTask 'default', ->
    grunt.log.writeln """
    Usage:
      - grunt serve
    """.yellow
