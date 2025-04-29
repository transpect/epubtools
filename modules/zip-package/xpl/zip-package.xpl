<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions"  
  xmlns:xsd="http://www.w3.org/2001/XMLSchema"
  xmlns:epub="http://transpect.io/epubtools" 
  xmlns:tr="http://transpect.io" 
  version="1.0"
  type="epub:zip-package" 
  name="zip-package">

  <p:documentation> This step expects a file manifest as input and creates a zip-package. The file manifest should have
    been this form:
    <!--
            <cx:document>
                <c:file name="epub/OEBPS/content.opf"/>
            </cx:document>
        -->
  </p:documentation>

  <p:input port="ocf-filerefs"/>
  <p:input port="opf-fileref"/>
  <p:input port="ops-filerefs"/>
  <p:input port="meta"/>
  <p:output port="result" primary="true"/>
  <p:output port="files" primary="false">
    <p:pipe port="result" step="generate-zip-manifest"/>
  </p:output>

  <p:option name="base-uri" required="true" cx:type="xsd:anyURI"/>
  <p:option name="target-zip-uri" select="'_unset_'"/>
  <p:option name="debug" select="'no'"/>
  <p:option name="debug-dir-uri" select="'debug'"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>

  <tr:store-debug pipeline-step="epubtools/zip-package/opf-filelist">
    <p:input port="source">
      <p:pipe port="opf-fileref" step="zip-package"/>
    </p:input>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:sink/>

  <tr:store-debug pipeline-step="epubtools/zip-package/ops-filelist">
    <p:input port="source">
      <p:pipe port="ops-filerefs" step="zip-package"/>
    </p:input>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:sink/>

  <tr:store-debug pipeline-step="epubtools/zip-package/ocf-filelist">
    <p:input port="source">
      <p:pipe port="ocf-filerefs" step="zip-package"/>
    </p:input>
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:sink/>

  <p:pack wrapper="document" wrapper-prefix="cx" wrapper-namespace="http://xmlcalabash.com/ns/extensions">
    <p:input port="source">
      <p:pipe port="opf-fileref" step="zip-package"/>
    </p:input>
    <p:input port="alternate">
      <p:pipe port="ops-filerefs" step="zip-package"/>
    </p:input>
  </p:pack>

  <p:pack wrapper="document" wrapper-prefix="cx" wrapper-namespace="http://xmlcalabash.com/ns/extensions">
    <p:input port="alternate">
      <p:pipe port="ocf-filerefs" step="zip-package"/>
    </p:input>
  </p:pack>

  <p:filter select="//c:file"/>

  <p:wrap-sequence wrapper="document" wrapper-prefix="cx" wrapper-namespace="http://xmlcalabash.com/ns/extensions"
                   name="wrap-file-uris"/>

  <tr:store-debug pipeline-step="epubtools/zip-package/merged-filelist">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:xslt name="generate-zip-manifest">
    <p:with-param name="epubdir" select="replace($base-uri, '^(.*[/])+(.*)', '$1')"/>
    <p:input port="stylesheet">
      <p:document href="../xsl/generate-zip-manifest.xsl"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="epubtools/zip-package/zip-manifest">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:group>
    <p:variable name="zip-file-uri"
      select="(
                $target-zip-uri, 
                replace($base-uri, 
                        '^(.+/)([^./]+)\.(xhtml|html|xml)$', 
                        concat('$1', if (normalize-space(/epub-config/@out-file-basename)) 
                                     then /epub-config/@out-file-basename 
                                     else '$2', 
                        '.epub'))
              )[not(. = '_unset_')][1]">
      <p:pipe port="meta" step="zip-package"/>
    </p:variable>

    <cx:zip command="create" name="zip">
      <p:with-option name="href" select="$zip-file-uri"/>
      <p:input port="source">
        <p:empty/>
      </p:input>
      <p:input port="manifest">
        <p:pipe step="generate-zip-manifest" port="result"/>
      </p:input>
    </cx:zip>

    <tr:store-debug pipeline-step="epubtools/zip-package/zip-result">
      <p:with-option name="active" select="$debug"/>
      <p:with-option name="base-uri" select="$debug-dir-uri"/>
    </tr:store-debug>
  </p:group>

</p:declare-step>
