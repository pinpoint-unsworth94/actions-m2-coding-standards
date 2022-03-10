'use strict';
const {src, dest, watch, series, parallel} = require('gulp');
const sassLint = require('gulp-sass-lint');
const eslint = require('gulp-eslint');

// Sass Lint
function sasslint() {
  console.log(arg.path); return;
    return src('../app/design/frontend/**/**/**/*.s+(a|c)ss', '!node_modules/**')
        .pipe(sassLint())
        .pipe(sassLint.format())
        .pipe(sassLint.failOnError());
}

// JS Lint
function jsLint() {
    return src(['../app/design/frontend/**/**/**/*.js', '!node_modules/**'])
        .pipe(eslint({
            configFile: '.eslintrc',
            fix: true
        }))
        .pipe(eslint.format())
        .pipe(eslint.failAfterError());
}

exports.lint = series(
    parallel(sasslint, jsLint)
);
