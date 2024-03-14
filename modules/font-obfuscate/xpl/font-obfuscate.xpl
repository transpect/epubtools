<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step" 
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:pxf="http://exproc.org/proposed/steps/file"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:css="http://www.w3.org/1996/css"
  xmlns:enc="http://www.w3.org/2001/04/xmlenc#"
  xmlns:tr="http://transpect.io"
  version="1.0"
  name="font-obfuscate"
  type="tr:font-obfuscate" exclude-inline-prefixes="#all">
  
  <p:documentation>
    This step applies the EPUB font obfuscation algorithm to 
    all font files that are declared in the CSS.
  </p:documentation>
  
  <p:input port="source" primary="true">
    <p:documentation>
      An expanded CSS document
    </p:documentation>
  </p:input>
  <p:input port="meta" primary="false">
    <p:documentation>
      The epub-config document
    </p:documentation>
  </p:input>
  
  <p:output port="result">
    <p:documentation>
      &lt;c:file/> document representing the file reference to the encryption XML
    </p:documentation>
  </p:output>
  
  <p:option name="targetdir"/>
  <p:option name="debug" select="'no'"/>
  <p:option name="debug-dir-uri" select="'debug-dir-uri'"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  
  <p:variable name="epub-uid" select="/epub-config/metadata/dc:identifier[1]">
    <p:pipe port="meta" step="font-obfuscate"/>
  </p:variable>
  
  <p:variable name="encryption-xml-href" select="concat($targetdir, 'epub/META-INF/encryption.xml')"/>
  
  <cx:message>
    <p:with-option name="message" select="'[info] starting font obfuscation'"/>
  </cx:message>
  
  <p:for-each name="font-iteration">
    <p:iteration-source select="/css:css/css:atrule[@type eq 'font-face']"/>
    <p:variable name="font-href" 
                select="css:atrule/css:declaration[@property eq 'src']/css:resource/@local-href"/>
    <p:variable name="obfuscated-font-href" 
                select="concat($font-href, '.obfuscated')"/>
    <p:variable name="args" select="concat('-jar epubtools/scripts/epub-font-obfuscator.jar ', $epub-uid, ' ', $font-href, ' ', $obfuscated-font-href)"/>
    
    <cx:message>
      <p:with-option name="message" select="'[info] obfuscating ', $font-href"/>
    </cx:message>
    
    <cx:message>
      <p:with-option name="message" select="'[info] target dir ', $targetdir"/>
    </cx:message>
    
    <p:exec command="java" result-is-xml="false" name="run-epub-font-obfuscator">
      <p:with-option name="args" select="$args"/>
    </p:exec>
    
    <pxf:copy cx:depends-on="run-epub-font-obfuscator">
      <p:with-option name="href" select="$obfuscated-font-href"/>
      <p:with-option name="target" select="$font-href"/>
    </pxf:copy>
    
    <p:add-attribute match="enc:EncryptedData/enc:CipherData/enc:CipherReference" attribute-name="URI">
      <p:with-option name="attribute-value" select="concat('OEBPS/fonts/', replace($font-href, '^.+/(.+?)$',  '$1'))"/>
      <p:input port="source">
        <p:inline><EncryptedData xmlns="http://www.w3.org/2001/04/xmlenc#"><EncryptionMethod Algorithm="http://www.idpf.org/2008/embedding"/><CipherData><CipherReference/></CipherData></EncryptedData></p:inline>
      </p:input>
    </p:add-attribute>
    
  </p:for-each>
  
  <p:wrap-sequence wrapper="encryption" wrapper-namespace="urn:oasis:names:tc:opendocument:xmlns:container" name="encryption-xml"/>    
  
  <tr:store-debug pipeline-step="epubtools/font-obfuscate/02_encryption-xml">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:store name="store-encryption-xml" indent="true">
    <p:with-option name="href" select="$encryption-xml-href"/>
  </p:store>
  
  <p:add-attribute match="/c:file" attribute-name="href" name="encryption-xml-href">
    <p:input port="source">
      <p:inline>
        <c:file oebps-name="META-INF/encryption.xml"/>
      </p:inline>
    </p:input>
    <p:with-option name="attribute-value" select="$encryption-xml-href"/>
  </p:add-attribute>
  
  <p:add-attribute match="/c:file" attribute-name="local-href">
    <p:with-option name="attribute-value" select="$encryption-xml-href"/>
  </p:add-attribute>
  
  <p:add-attribute match="/c:file" attribute-name="target-filename">
    <p:with-option name="attribute-value" select="$encryption-xml-href"/>
  </p:add-attribute>
  
</p:declare-step>