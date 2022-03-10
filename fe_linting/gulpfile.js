'use strict';
const {src, dest, watch, series, parallel} = require('gulp');
const sassLint = require('gulp-sass-lint');
const eslint = require('gulp-eslint');
const arg = (argList => {
    let arg = {}, a, opt, thisOpt, curOpt;
    for (a = 0; a < argList.length; a++) {
        thisOpt = argList[a].trim();
        opt = thisOpt.replace(/^\-+/, '');
        if (opt === thisOpt) {
            // argument value
            if (curOpt) arg[curOpt] = opt;
            curOpt = null;
        }
        else {
            // argument name
            curOpt = opt;
            arg[curOpt] = true;
        }
    }
    return arg;
})(process.argv);

// Sass Lint
function sasslint() {
    let files = filterOnlyThemeChanges(arg.sass);
    console.log('Running SASS linting on:')
    console.log(files);
    return src(files, {"allowEmpty": true})
        .pipe(sassLint())
        .pipe(sassLint.format())
        .pipe(sassLint.failOnError());
}

// JS Lint
function jsLint() {
    let files = filterOnlyThemeChanges(arg.js);
    console.log('Running JS linting on:')
    console.log(files);
    return src(files, {"allowEmpty": true})
        .pipe(eslint({
            configFile: '.eslintrc',
            fix: true
        }))
        .pipe(eslint.format())
        .pipe(eslint.failAfterError());
}

function filterOnlyThemeChanges(files) {
  if (files === 'false' || typeof files === 'undefined') return ['false'];

  files = files.split(' ');
  files = files.filter(file => file.includes('app/design')).map(file => '../' + file);

  if (!files.length) {
    return ['false'];
  }
}

exports.lint = series(
    parallel(sasslint, jsLint)
);
