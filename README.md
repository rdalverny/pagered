# Page Reducer

Very quick and sketchy way to minify a given Web document:

 - get HTML document;
 - gather all referenced CSS files, replace them
   with a single ref pointing to a new ad hoc static,
   reduced and minified CSS file;
 - (TODO) do the same for JS;
 - rewrite HTML doc, minify it.


## Dependencies

 * Ruby, Nokogiri, HTMLCompressor
 * UnCSS - https://github.com/giakki/uncss
 * YUICompressor - https://github.com/yui/yuicompressor/

### Install & Use

```shell
$ brew uncss yuicompressor
OR
$ npm i uncss yuicompressor
$ gem install nokogiri htmlcompressor
$ ./red.rb http://yoursite/
```
