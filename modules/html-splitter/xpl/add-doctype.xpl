<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:tr="http://transpect.io" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  version="1.0" 
  type="tr:add-doctype">
  
  <p:option name="file-uri"/>
  <p:option name="os"/>
  <p:option name="cwd"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  
  <p:exec result-is-xml="false" 
          wrap-result-lines="true" 
          wrap-error-lines="true">
    <p:with-option name="command" 
                   select="concat(
                             $cwd, 
                             if(matches($os, 'windows', 'i')) 
                             then '/epubtools/scripts/add-doctype.bat' 
                             else '/epubtools/scripts/add-doctype.sh'
                           )"/>
    <p:with-option name="args" select="replace($file-uri, '^(file:|file:///)', '')"/>
    <p:input port="source">
      <p:empty/>
    </p:input>
  </p:exec>
  
  <p:sink/>
  
</p:declare-step>
