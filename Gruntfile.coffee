'use strict'

path = require 'path'

module.exports = (grunt) ->

    # load grunt tasks
    (require 'matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)

    _ = grunt.util._
    path = require 'path'

    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'
        dirs:
            src: "src"
            views: "views"
            client: "client"
            scripts: "public/scripts"
            server: "server"

        coffeelint:
            gruntfile:
                src: '<%= watch.gruntfile.files %>'
            src:
                src: '<%= dirs.src %>/**/*.coffee'
            client:
                src: '<%= dirs.client %>/**/*.coffee'
            options:
                configFile: 'coffeelint.json'

        coffee:
            compile:
                files:
                    'public/scripts/four-cardboard.js': 'client/cardboard/**/*.coffee'
                    'public/scripts/four-leap.js': 'client/leap/**/*.coffee'

        uglify:
            public:
                files:
                    'public/scripts/four-cardboard-min.js': 'public/scripts/four-cardboard.js'
                    'public/scripts/four-leap-min.js': 'public/scripts/four-leap.js'

        watch:
            options:
                spawn: false
            gruntfile:
                files: 'Gruntfile.coffee'
                tasks: ['coffeelint:gruntfile']
            client:
                files: ['<%= dirs.client %>/**/*.coffee']
                tasks: ['coffeelint', 'coffee', 'uglify']

        clean:
            scripts: ['<%= dirs.scripts %>']

        nodemon:
            dev:
                script: 'app.js'

        notify:
            serve:
                options:
                    title: 'Started four server'
                    message: 'Server is running at localhost.'


    grunt.registerTask 'build', [
        'clean'
        'coffeelint'
        'coffee'
        'uglify'
    ]

    grunt.registerTask 'serve', [
        'build'
        'nodemon'
        'notify:serve'
    ]

    grunt.registerTask 'default', [
        'build'
        'serve'
    ]



