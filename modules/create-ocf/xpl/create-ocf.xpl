<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:cxo="http://xmlcalabash.com/ns/extensions/osutils" 
  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:epub="http://transpect.io/epubtools"  
  version="1.0"
  type="epub:create-ocf" 
  name="create-ocf">

  <p:documentation> This step is used to create the directory structure of the OCF Abstract Container. It is required to provide
    as option the path to the source html file. </p:documentation>
  
  <p:input port="meta">
    <p:documentation>an epub-config document, see epub:convert</p:documentation>
  </p:input>
  <p:output port="result" primary="true" sequence="true">
    <p:pipe port="result" step="create"/>
  </p:output>
  <p:output port="files" primary="false">
    <p:pipe step="basic-files" port="result"/>
  </p:output>
  
  <p:option name="base-uri" required="true" cx:type="xsd:anyURI"/>
  <p:option name="debug" select="'no'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>  

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  
  <p:variable name="variant" select="(/epub-config/@variant, '')[1]" cx:type="xs:string">
    <p:pipe port="meta" step="create-ocf"/>
  </p:variable>
  
  <p:variable name="layout" select="(/epub-config/@layout, 'reflowable')[1]" cx:type="xs:string">
    <p:pipe port="meta" step="create-ocf"/>
  </p:variable>

  <p:group name="basic-files">
    <p:output port="result">
      <p:pipe port="result" step="which-files"/>
    </p:output>
    <p:choose name="which-files">
      <p:when test="not(tokenize($variant, '\s+') = ('FIXED-Apple', 'ORIGINAL-CSS')
                        or $layout = 'fixed')">
        <p:output port="result" primary="true"/>
        <p:identity name="basic-files-1">
          <p:input port="source">
            <p:inline>
              <cx:document>
                <c:file oebps-name="mimetype"/>
                <c:file oebps-name="META-INF/container.xml"/>
              </cx:document>
            </p:inline>
          </p:input>
        </p:identity>
      </p:when>
      <p:otherwise>
        <p:output port="result" primary="true"/>
        <p:identity name="basic-files-2">
          <p:input port="source">
            <p:inline>
              <cx:document>
                <c:file oebps-name="mimetype"/>
                <c:file oebps-name="META-INF/container.xml"/>
                <c:file oebps-name="META-INF/com.apple.ibooks.display-options.xml"/>
              </cx:document>
            </p:inline>
          </p:input>
        </p:identity>
      </p:otherwise>
    </p:choose>
    <p:sink/>
  </p:group>
 
  <p:group name="apple-display">
    <p:output port="result">
      <p:pipe port="result" step="load-options"/>
    </p:output>
    <p:choose name="load-options">
      <p:when test="tokenize($variant, '\s+') = 'ORIGINAL-CSS'">
        <p:output port="result">
          <p:pipe port="result" step="right-options"/>
        </p:output>
        <p:identity/>
        <p:sink/>
      </p:when>
      <p:otherwise>
        <p:output port="result">
          <p:document href="../xml/com.apple.ibooks.display-options.xml"/>
        </p:output>
        <p:identity/>
        <p:sink/>
      </p:otherwise>
    </p:choose>
  </p:group>
  
  <p:sink/>
  
  <p:delete name="right-options" match="*:option[@name ne 'specified-fonts']">
    <p:input port="source">
      <p:document href="../xml/com.apple.ibooks.display-options.xml"/>
    </p:input>
  </p:delete>
  
  <p:sink/>
  
    <p:group name="create" cx:depends-on="right-options">
      <p:output port="result" sequence="true">
        <p:pipe port="result" step="fixed"/>
      </p:output>
      <p:variable name="workdir" select="replace($base-uri, '^(.*[/])+(.*)', '$1')"/>
      <!--  *
            * p:identity is necessary because cxf:delete sometimes doesn't work without p:identity 
            * -->
       
      <p:identity name="report">
        <p:input port="source"><p:empty/></p:input>
      </p:identity>

      <p:try name="clean">
        <p:group>
          <p:identity name="clean-input">
            <p:input port="source">
              <p:empty/>
            </p:input>
          </p:identity>
          
          <cxf:delete recursive="true" fail-on-error="false" name="del">
            <p:with-option name="href" select="concat($workdir, 'epub')"/>
          </cxf:delete>
        </p:group>
        
        <p:catch>
          <p:identity name="clean-error">
            <p:input port="source">
              <p:inline>
                <c:error>Deleting EPUB directory failed</c:error>
              </p:inline>
            </p:input>
          </p:identity>
          <cx:message>
            <p:with-option name="message" select="'[ERROR:] Could not delete: ', concat($workdir, 'epub')"></p:with-option>
          </cx:message>
          <p:sink/>
        </p:catch>
      </p:try>


      <!--  *
            * create OCF directories
            * -->
      <cxf:mkdir name="mkdir1" cx:depends-on="clean">
        <p:with-option name="href" select="concat($workdir, 'epub')"/>
      </cxf:mkdir>

      <cxf:mkdir name="mkdir2" cx:depends-on="mkdir1">
        <p:with-option name="href" select="concat($workdir, 'epub/META-INF')"/>
      </cxf:mkdir>

      <cxf:mkdir name="mkdir3" cx:depends-on="mkdir2">
        <p:with-option name="href" select="concat($workdir, 'epub/OEBPS')"/>
      </cxf:mkdir>

      <p:store method="xml" media-type="text/xml" omit-xml-declaration="false" name="store1" cx:depends-on="mkdir3">
        <p:with-option name="href" select="concat($workdir, 'epub/META-INF/container.xml')"/>
        <p:input port="source">
          <p:document href="../xml/container.xml"/>
        </p:input>
      </p:store>
      
      <p:store method="text" media-type="text/plain" encoding="US-ASCII" cx:depends-on="store1" name="store2">
        <p:with-option name="href" select="concat($workdir, 'epub/mimetype')"/>
        <p:input port="source">
          <p:inline><c:data method="text" media-type="text/plain" encoding="US-ASCII">application/epub+zip</c:data></p:inline>
        </p:input>
      </p:store>
      
      <p:choose name="fixed" cx:depends-on="store2">
        <p:when test="$layout = 'fixed' or tokenize($variant, '\s+') = 'ORIGINAL-CSS'">
          <p:output port="result" sequence="true">
            <p:pipe port="result" step="try-fixed"/>
          </p:output>
          <p:try name="try-fixed">
            <p:group>
              <p:output port="result">
                <p:pipe port="result" step="apple-meta"/>
              </p:output>
              <!--  * 
                    * check for an existing com.apple.ibooks.display-options.xml, otherwise break and switch to catch subpipeline 
                    * -->
              <cxf:info fail-on-error="true">
                <p:with-option name="href" select="concat($workdir, 'com.apple.ibooks.display-options.xml')"/>
              </cxf:info>

              <p:load name="load-applemetadata">
                <p:with-option name="href" select="concat($workdir, 'com.apple.ibooks.display-options.xml')"/>
              </p:load>
              
              <p:store name="apple-meta" method="xml" media-type="text/xml" omit-xml-declaration="false">
                <p:with-option name="href" select="concat($workdir, 'epub/META-INF/com.apple.ibooks.display-options.xml')"/>
                <p:input port="source">
                  <p:pipe port="result" step="load-applemetadata"/>
                </p:input>
              </p:store>
              
            </p:group>
            <p:catch>
              <p:output port="result">
                <p:pipe port="result" step="otherwise"/>
              </p:output>
              <p:store name="otherwise" method="xml" media-type="text/xml" omit-xml-declaration="false">
                <p:with-option name="href" select="concat($workdir, 'epub/META-INF/com.apple.ibooks.display-options.xml')"/>
                <p:input port="source">
                  <p:pipe port="result" step="apple-display"/>
                </p:input>
              </p:store>

            </p:catch>
          </p:try>

        </p:when>
        <p:otherwise>
          <p:output port="result" sequence="true">
            <p:empty/>
          </p:output>
          <p:sink name="sink">
            <p:input port="source">
              <p:empty/>
            </p:input>
          </p:sink>
        </p:otherwise>
      </p:choose>
      
      <p:sink/>
      
    </p:group>
    
</p:declare-step>